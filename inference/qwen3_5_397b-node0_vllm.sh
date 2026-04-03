#!/bin/bash

###################################
# Qwen3.5-397B-A17B-W8A8  主节点 (rank=0) 启动脚本
# 配置：TP8 DP2，2 节点，每节点 8 卡
# 上下文：256k (262144 tokens)
#
# 使用方式：
#   1. 在主节点机器上直接执行本脚本
#   2. 脚本会自动获取本机 eth0 IP 并打印，将该 IP 填入从节点脚本的 MASTER_NODE_IP
#   3. 等待主节点打印 "Starting vLLM..." 后，再在从节点执行 node1 脚本
###################################


# 2. 核心环境变量设置
ulimit -n 65536

# MACA 算子与内存优化
export MACA_GRAPH_LAUNCH_MODE=5
export MACA_SMALL_PAGESIZE_ENABLE=1
export MACA_DIRECT_DISPATCH=1
export MACA_VLLM_ENABLE_MCTIASS_FUSED_MOE=1
export MACA_VLLM_ENABLE_MCTIASS_PYTHON_API=1
export TRITON_ENABLE_MACA_OPT_MMA_PREFETCH=1
export TRITON_ENABLE_MACA_COMPILER_INT8_OPT=True
export TRITON_ENABLE_ELEMENTWISE_PK_FMA_OPT=True

# 网络配置
export GLOO_SOCKET_IFNAME=eth0
export MCCL_SOCKET_IFNAME=eth0
export MCCL_IB_HCA=mlx5_0,mlx5_1

# 3. 离线模式设置
export HF_DATASETS_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export VLLM_NO_USAGE_STATS=1

# 4. 模型路径与配置
export MODEL_PATH="/mnt/afs/models/metax-tech/Qwen3.5-397B-A17B-W8A8"
BLOCK_SIZE=${BLOCK_SIZE:-64}

set -o pipefail

# 5. 获取本机 IP（作为 master-addr 告知从节点）
MASTER_NODE_IP=$(ifconfig eth0 | grep "inet " | awk '{print $2}')
if [ -z "$MASTER_NODE_IP" ]; then
    echo "ERROR: 无法从 eth0 获取本机 IP，请手动设置 MASTER_NODE_IP"
    exit 1
fi

echo "============================================"
echo "  主节点 (rank=0) 启动"
echo "  本机 IP (MASTER_NODE_IP): ${MASTER_NODE_IP}"
echo "  请将此 IP 填入从节点脚本的 MASTER_NODE_IP 变量"
echo "  Model Path : $MODEL_PATH"
echo "  Block Size : $BLOCK_SIZE"
echo "============================================"

# 6. 启动 vLLM 主节点
vllm serve $MODEL_PATH \
    --served-model-name Qwen3.5-397B \
    --trust-remote-code \
    -tp 8 -dp 2 \
    --distributed-executor-backend mp \
    --master-addr ${MASTER_NODE_IP} \
    --nnodes 2 \
    --node-rank 0 \
    --host 0.0.0.0 \
    --port 8089 \
    --block-size ${BLOCK_SIZE} \
    --max-model-len 262144 \
    --max-num-seqs 32 \
    --max_num_batched_tokens 32768 \
    --gpu-memory-utilization 0.90 \
    --no-async-scheduling \
    --no-enable-prefix-caching \
    --enable-auto-tool-choice \
    --tool-call-parser qwen3_coder \
    --default-chat-template-kwargs '{"enable_thinking": false}' \
    --mm-encoder-tp-mode data \
    --mm-processor-cache-type shm \
    --limit-mm-per-prompt '{"image": 5, "video": 1}' \
    --skip-mm-profiling
