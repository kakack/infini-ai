#!/bin/bash 

################################### 
# 训练任务中启动 vllm 推理的脚本 
# 优化版：不依赖 Ray Dashboard，修复端口冲突，强制离线模式，修复换行符问题
################################### 
sudo apt install -y dnsutils net-tools netcat-openbsd 
export MCCL_SOCKET_IFNAME=eth0 
export MCCL_IB_HCA=mlx5_0,mlx5_1 
export RAY_EXPERIMENTAL_NOSET_CUDA_VISIBLE_DEVICES=1 
export MACA_DIRECT_DISPATCH=1 
export TRITON_ENABLE_MACA_OPT_MMA_PREFETCH=1 
export TRITON_ENABLE_MACA_COMPILER_INT8_OPT=True 
export TRITON_ENABLE_ELEMENTWISE_PK_FMA_OPT=True 
export GLOO_SOCKET_IFNAME=eth0 
export MCCL_SOCKET_IFNAME=eth0 
export VLLM_USE_RAY_COMPILED_DAG_CHANNEL_TYPE=nccl
unset VLLM_USE_RAY_COMPILED_DAG_OVERLAP_COMM


# Fix: 强制使用离线模式，禁止连接 Hugging Face
export HF_DATASETS_OFFLINE=1 
export TRANSFORMERS_OFFLINE=1 
export VLLM_NO_USAGE_STATS=1 
# 确保使用本地模型路径，而不是尝试从 hub 下载
# 请确保此路径真实存在！
export MODEL_PATH="/mnt/public/model/huggingface/Qwen3-Coder-480B-A35B-Instruct-W8A8"

set -o pipefail 

MASTER_ADDR=${MASTER_ADDR:-"localhost"} 
NODE_RANK=${RANK:-"0"} 
NNODES=${WORLD_SIZE:-"1"} 

################################### 
# 启动 ray cluster 
################################### 

# 准备 ray command
RAY_START_CMD="ray start" 
# 获取 head 节点的 ip 地址
HEAD_NODE_ADDRESS=$(dig $MASTER_ADDR |grep -A 1 "ANSWER SECTION" |grep "$MASTER_ADDR" | awk '{print $5}') 

# 容错：如果 dig 解析失败，直接使用 MASTER_ADDR
if [ -z "$HEAD_NODE_ADDRESS" ]; then
    HEAD_NODE_ADDRESS=$MASTER_ADDR
fi

# worker 端口范围须避开以下已知端口：
#   runtime_env_agent: 19700, metrics_export: 20000, dashboard_agent_grpc: 21001
# 使用 25000-29999 可完全规避冲突
PORT_PARAMS="--min-worker-port=25000 --max-worker-port=29999 --dashboard-agent-grpc-port=21001 --metrics-export-port=20000 --num-gpus=8"
             
if [ "$NODE_RANK" -eq 0 ]; then 
    # node 0 作为 head 节点 
    # 保持 --include-dashboard=False，因为 Dashboard 不可用
    RAY_START_CMD+=" --head --port=6379 --disable-usage-stats --include-dashboard=False $PORT_PARAMS" 
else 
    # 等待 head 节点起来后再启动 worker 节点 
    while ! nc -zv $MASTER_ADDR 6379 >/dev/null 2>&1; do 
        echo "Waiting for ray head node to be ready..." 
        sleep 1 
    done 
    # 其他节点作为 worker 节点加入到 head 节点构成 ray cluster 
    RAY_START_CMD+=" --block --address=${HEAD_NODE_ADDRESS}:6379 $PORT_PARAMS" 
fi 

# 确保在启动前停止旧实例
ray stop --force >/dev/null 2>&1 
# 启动 ray cluster
echo "Executing: $RAY_START_CMD" 
$RAY_START_CMD 

################################### 
# 在 head 节点上启动 vllm serving 
################################### 

# set local vllm host ip 
export VLLM_HOST_IP=$(ifconfig eth0 | grep "inet " | awk '{print $2}') 
echo "VLLM_HOST_IP: ${VLLM_HOST_IP}" 

if [ "$NODE_RANK" -eq 0 ]; then 
    # 等待所有 ray workers 都加入 ray cluster 
    echo "Waiting for $NNODES nodes to join the cluster..."
    while :; do 
        # 核心修改：使用 Python SDK 直接查询 GCS 状态，不依赖 Dashboard API
        # ray.nodes() 返回所有注册节点列表，筛选 Alive 状态的节点
        ready_nodes=$(python3 -c "import ray; ray.init(address='auto', logging_level='error'); print(len([n for n in ray.nodes() if n['Alive']]))" 2>/dev/null)
        
        # 检查返回值是否为有效数字
        if [[ "$ready_nodes" =~ ^[0-9]+$ ]]; then
            echo "Current ready nodes: $ready_nodes / $NNODES"
            if [ "$ready_nodes" -ge "$NNODES" ]; then
                break
            fi
        fi
 
        sleep 1 
    done 
    
    echo "All nodes ready. Starting vLLM..."

    # run vllm serving 
    # Fix: 移除了所有换行符后的潜在空格
    python -m vllm.entrypoints.openai.api_server \
      --model $MODEL_PATH \
      --served-model-name Qwen3-Coder-480B \
      --tensor-parallel-size 8 \
      --pipeline-parallel-size 4 \
      --distributed-executor-backend ray \
      --host 0.0.0.0 \
      --port 8089 \
      --swap-space 16 \
      --gpu-memory-utilization 0.85 \
      --max-model-len 131072 \
      --dtype auto \
      --enable-expert-parallel \
      --enforce-eager \
      --trust-remote-code 
fi