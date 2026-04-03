#!/bin/bash

###################################
# Qwen3.5-397B-A17B-W8A8  从节点 (rank=1) 启动脚本
# 配置：TP8 DP2，2 节点，每节点 8 卡
# 上下文：256k (262144 tokens)
#
# 使用方式：
#   1. 先在主节点执行 node0 脚本，等待主节点打印本机 IP
#   2. 将主节点 IP 填入下方 MASTER_NODE_IP 变量
#   3. 在从节点机器上执行本脚本
###################################

# ★ 必须修改：填入主节点 (node0) 的实际 IP 地址
MASTER_NODE_IP="10.119.34.141"

###################################

# 启动前检查
if [ "$MASTER_NODE_IP" = "<请填入主节点IP>" ]; then
    echo "ERROR: 请先将 MASTER_NODE_IP 修改为主节点的实际 IP 地址！"
    exit 1
fi

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

# 4. 模型路径与配置（需与主节点保持一致）
export MODEL_PATH="/mnt/afs/models/metax-tech/Qwen3.5-397B-A17B-W8A8"
BLOCK_SIZE=${BLOCK_SIZE:-64}

set -o pipefail

echo "============================================"
echo "  从节点 (rank=1) 启动"
echo "  主节点 IP (MASTER_NODE_IP): ${MASTER_NODE_IP}"
echo "  Model Path : $MODEL_PATH"
echo "  Block Size : $BLOCK_SIZE"
echo "============================================"

# 5. 启动 vLLM 从节点（--headless 仅参与计算，不对外提供 API）
# 注意：不需要等待主节点的任何端口就绪，与主节点同时启动即可。
# vllm 的 --nnodes + --node-rank 机制会在 DP 进程组初始化阶段自动同步两个节点。
# 若在主节点模型加载完成后才启动，会导致主节点 TCPStore 等待超时（601s）。
vllm serve $MODEL_PATH \
    --served-model-name Qwen3.5-397B \
    --trust-remote-code \
    -tp 8 -dp 2 \
    --distributed-executor-backend mp \
    --master-addr ${MASTER_NODE_IP} \
    --nnodes 2 \
    --node-rank 1 \
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
    --skip-mm-profiling \
    --headless
