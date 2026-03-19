#!/bin/bash

###################################
# 平台任务启动脚本：VLLM 推理
# 适用模型：GLM-5
# 配置：TP4 DP4 (共 2 节点，每节点 8 卡，合计 16 卡)
# 启动方式：vLLM 原生多节点 (mp backend + --nnodes + --node-rank)
# 参考：交付工程师 GLM-5 C500 裸金属部署示例
###################################

# 1. 基础依赖安装 (如果镜像已包含可注释)
sudo apt install -y dnsutils net-tools netcat-openbsd

# 2. 核心环境变量设置 (参照官方 GLM-5 部署示例)
ulimit -n 65536

# MACA 算子与内存优化
export MACA_SMALL_PAGESIZE_ENABLE=1
export VLLM_DISABLE_SHARED_EXPERTS_STREAM=1
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:128,garbage_collection_threshold:0.6,expandable_segments:True"
export DISABLE_MAP2XPU=1
export MACA_VLLM_ENABLE_MCTLASS_PYTHON_API=1
export MACA_VLLM_ENABLE_MCTLASS_FUSED_MOE=1  # 使用 mctlass_moe，部分场景不配置使用默认 triton_moe 性能更好

# 网络配置 (裸金属示例为 enp33s0np0，平台环境使用 eth0)
export GLOO_SOCKET_IFNAME=eth0
export MCCL_SOCKET_IFNAME=eth0
export MCCL_IB_HCA=mlx5_0,mlx5_1

# 3. 离线模式设置
export HF_DATASETS_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export VLLM_NO_USAGE_STATS=1

# 4. 模型路径
export MODEL_PATH="/mnt/public/model/huggingface/metax-tech/GLM-5-W8A8"

# 5. 自动解析平台注入的环境变量
MASTER_ADDR=${MASTER_ADDR:-"localhost"}
NODE_RANK=${RANK:-"0"}
NNODES=${WORLD_SIZE:-"2"}

set -o pipefail

# 6. 获取 Head 节点 IP (平台注入的 MASTER_ADDR 可能是 hostname，需解析为 IP)
HEAD_NODE_ADDRESS=$(dig $MASTER_ADDR | grep -A 1 "ANSWER SECTION" | grep "$MASTER_ADDR" | awk '{print $5}')
if [ -z "$HEAD_NODE_ADDRESS" ]; then
    HEAD_NODE_ADDRESS=$MASTER_ADDR
fi

echo "--- VLLM Multi-Node Info ---"
echo "Master Node IP : $HEAD_NODE_ADDRESS"
echo "Current Node Rank: $NODE_RANK"
echo "Total Nodes    : $NNODES"
echo "Model Path     : $MODEL_PATH"
echo "----------------------------"

###################################
# 7. 启动 vLLM Server
#    主节点 (rank=0)：监听 8089 端口对外提供服务
#    从节点 (rank≠0)：--headless 模式，仅参与计算
###################################

if [ "$NODE_RANK" -eq 0 ]; then
    echo "#### Main Node (rank=0): starting vLLM with --port 8089"
    vllm serve $MODEL_PATH \
        --served-model-name GLM-5 \
        --trust-remote-code \
        -tp 4 -dp 4 \
        --distributed-executor-backend mp \
        --master-addr ${HEAD_NODE_ADDRESS} \
        --nnodes ${NNODES} \
        --node-rank ${NODE_RANK} \
        --host 0.0.0.0 \
        --port 8089 \
        --max-model-len 5140 \
        --max-num-seqs 64 \
        --gpu-memory-utilization 0.9 \
        --speculative_config '{"method": "mtp", "num_speculative_tokens": 1}' \
        --no-async-scheduling \
        --no-enable-prefix-caching
else
    echo "#### Worker Node (rank=$NODE_RANK): starting vLLM with --headless"
    vllm serve $MODEL_PATH \
        --served-model-name GLM-5 \
        --trust-remote-code \
        -tp 4 -dp 4 \
        --distributed-executor-backend mp \
        --master-addr ${HEAD_NODE_ADDRESS} \
        --nnodes ${NNODES} \
        --node-rank ${NODE_RANK} \
        --max-model-len 5140 \
        --max-num-seqs 64 \
        --gpu-memory-utilization 0.9 \
        --speculative_config '{"method": "mtp", "num_speculative_tokens": 1}' \
        --no-async-scheduling \
        --no-enable-prefix-caching \
        --headless
fi
