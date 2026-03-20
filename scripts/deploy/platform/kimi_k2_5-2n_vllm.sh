#!/bin/bash

###################################
# 平台任务启动脚本：VLLM 推理
# 适用模型：Kimi-K2.5
# 配置：TP16（共 2 节点，每节点 8 卡，合计 16 卡，全量 TP）
# 启动方式：Ray cluster + vLLM serve
#
# 注意：工程师参考命令中的 CUDA_VISIBLE_DEVICES 特定 GPU 顺序
#   (0,1,2,3,6,5,4,7,10,9,8,11,14,15,12,13) 是裸金属拓扑优化顺序。
#   平台环境由调度器管理 GPU 分配，无需手动指定；若需针对特定节点
#   拓扑调优，可在此处设置 CUDA_VISIBLE_DEVICES 后再启动。
###################################

# 1. 基础依赖安装
sudo apt install -y dnsutils net-tools netcat-openbsd

# 2. 核心环境变量设置
ulimit -n 65536

# MACA 算子优化
export MACA_DIRECT_DISPATCH=1
export TRITON_ENABLE_MACA_OPT_MMA_PREFETCH=1
export TRITON_ENABLE_MACA_COMPILER_INT8_OPT=True
export TRITON_ENABLE_ELEMENTWISE_PK_FMA_OPT=True

# 网络配置
export MCCL_SOCKET_IFNAME=eth0
export MCCL_IB_HCA=mlx5_0,mlx5_1
export GLOO_SOCKET_IFNAME=eth0

# Ray 相关：防止 Ray 覆盖 GPU 可见性设置
export RAY_EXPERIMENTAL_NOSET_CUDA_VISIBLE_DEVICES=1
export VLLM_USE_RAY_COMPILED_DAG_CHANNEL_TYPE=nccl
unset VLLM_USE_RAY_COMPILED_DAG_OVERLAP_COMM

# 3. 离线模式设置
export HF_DATASETS_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export VLLM_NO_USAGE_STATS=1

# 4. 模型路径
export MODEL_PATH="/mnt/public/model/huggingface/metax-tech/kimi-k2.5"

# 5. 自动解析平台注入的环境变量
MASTER_ADDR=${MASTER_ADDR:-"localhost"}
NODE_RANK=${RANK:-"0"}
NNODES=${WORLD_SIZE:-"2"}

set -o pipefail

# 6. 获取 Head 节点 IP
HEAD_NODE_ADDRESS=$(dig $MASTER_ADDR | grep -A 1 "ANSWER SECTION" | grep "$MASTER_ADDR" | awk '{print $5}')
if [ -z "$HEAD_NODE_ADDRESS" ]; then
    HEAD_NODE_ADDRESS=$MASTER_ADDR
fi

echo "--- Ray + VLLM Distributed Info ---"
echo "Master Node IP   : $HEAD_NODE_ADDRESS"
echo "Current Node Rank: $NODE_RANK"
echo "Total Nodes      : $NNODES"
echo "Model Path       : $MODEL_PATH"
echo "-----------------------------------"

###################################
# 7. 启动 Ray Cluster
###################################

# worker 端口范围须避开以下已知端口：
#   runtime_env_agent: 19700, metrics_export: 20000, dashboard_agent_grpc: 21001
# 使用 25000-29999 可完全规避冲突
PORT_PARAMS="--min-worker-port=25000 --max-worker-port=29999 --dashboard-agent-grpc-port=21001 --metrics-export-port=20000 --num-gpus=8"

ray stop --force >/dev/null 2>&1

RAY_START_CMD="ray start"

if [ "$NODE_RANK" -eq 0 ]; then
    RAY_START_CMD+=" --head --port=6379 --disable-usage-stats --include-dashboard=False $PORT_PARAMS"
else
    while ! nc -zv $MASTER_ADDR 6379 >/dev/null 2>&1; do
        echo "Waiting for ray head node to be ready..."
        sleep 1
    done
    RAY_START_CMD+=" --block --address=${HEAD_NODE_ADDRESS}:6379 $PORT_PARAMS"
fi

echo "Executing: $RAY_START_CMD"
$RAY_START_CMD

###################################
# 8. 在 Head 节点上启动 vLLM Server
###################################

export VLLM_HOST_IP=$(ifconfig eth0 | grep "inet " | awk '{print $2}')
echo "VLLM_HOST_IP: ${VLLM_HOST_IP}"

if [ "$NODE_RANK" -eq 0 ]; then
    echo "Waiting for $NNODES nodes to join the cluster..."
    while :; do
        ready_nodes=$(python3 -c "import ray; ray.init(address='auto', logging_level='error'); print(len([n for n in ray.nodes() if n['Alive']]))" 2>/dev/null)

        if [[ "$ready_nodes" =~ ^[0-9]+$ ]]; then
            echo "Current ready nodes: $ready_nodes / $NNODES"
            if [ "$ready_nodes" -ge "$NNODES" ]; then
                break
            fi
        fi

        sleep 1
    done

    echo "All nodes ready. Starting vLLM..."

    vllm serve $MODEL_PATH \
        --served-model-name Kimi-K2.5 \
        --trust-remote-code \
        -tp 16 \
        --distributed-executor-backend ray \
        --host 0.0.0.0 \
        --port 8089 \
        --max-model-len 32768 \
        --swap-space 16 \
        --gpu-memory-utilization 0.90 \
        --no-enable-prefix-caching \
        --tool-call-parser kimi_k2 \
        --reasoning-parser kimi_k2 \
        --mm-processor-cache-gb 32
fi
