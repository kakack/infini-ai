#!/bin/bash
# ============================================
# GLM-5 双节点部署脚本 (沐曦 C500)
# 配置: TP4 DP4, 2 Nodes, 每节点 8 卡
# ============================================

set -e

NODE_RANK="${RANK:-0}"
NNODES="${WORLD_SIZE:-2}"
MASTER_ADDR="${MASTER_ADDR:-10.201.45.145}"
MODEL_PATH="${MODEL_PATH:-/mnt/public/model/huggingface/metax-tech/GLM-5-W8A8}"

echo "========================================"
echo "GLM-5 双节点部署"
echo "========================================"
echo "当前节点 Rank: $NODE_RANK"
echo "总节点数: $NNODES"
echo "主节点地址: $MASTER_ADDR"
echo "模型路径: $MODEL_PATH"
echo "========================================"

# 系统限制
ulimit -n 65536

# MACA 环境变量
export MACA_SMALL_PAGESIZE_ENABLE=1
export VLLM_DISABLE_SHARED_EXPERTS_STREAM=1
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:128,garbage_collection_threshold:0.6,expandable_segments:True"
export DISABLE_MAP2XPU=1
export MACA_VLLM_ENABLE_MCTLASS_PYTHON_API=1
export MACA_VLLM_ENABLE_MCTLASS_FUSED_MOE=1

# 离线模式
export HF_DATASETS_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export VLLM_NO_USAGE_STATS=1

# 网络配置
export GLOO_SOCKET_IFNAME=eth0
export MCCL_SOCKET_IFNAME=eth0

# 构建启动参数
COMMON_ARGS=(
    --trust-remote-code
    -tp 4
    -dp 4
    --distributed-executor-backend mp
    --master-addr "$MASTER_ADDR"
    --nnodes "$NNODES"
    --node-rank "$NODE_RANK"
    --max-model-len 5140
    --max-num-seqs 64
    --gpu-memory-utilization 0.9
    --speculative-config '{"method": "mtp", "num_speculative_tokens": 1}'
    --no-async-scheduling
    --no-enable-prefix-caching
)

if [ "$NODE_RANK" -eq 0 ]; then
    echo "启动主节点 (rank=0)..."
    vllm serve "$MODEL_PATH" \
        "${COMMON_ARGS[@]}" \
        --served-model-name GLM-5
else
    echo "启动从节点 (rank=$NODE_RANK)..."
    vllm serve "$MODEL_PATH" \
        "${COMMON_ARGS[@]}" \
        --served-model-name GLM-5 \
        --headless
fi
