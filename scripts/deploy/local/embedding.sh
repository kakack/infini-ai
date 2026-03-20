#!/bin/bash
# ============================================
# Embedding 模型本地部署脚本
# 支持模型: bge-m3, bge-embedding-m3
# ============================================

set -e

# 配置
MODEL_PATH="${1:-/home/simon/memtensor/bge-m3}"
PORT="${2:-18089}"
GPU_UTIL="${3:-0.08}"

# 也可以使用 AFS 路径
# MODEL_PATH="/mnt/afs/models/bge-m3"

echo "========================================"
echo "部署 Embedding 模型"
echo "========================================"
echo "模型路径: $MODEL_PATH"
echo "服务端口: $PORT"
echo "GPU 利用率: $GPU_UTIL"
echo "========================================"

vllm serve "$MODEL_PATH" \
    --host 0.0.0.0 \
    --port "$PORT" \
    --served-model-name bge-m3 \
    --gpu-memory-utilization "$GPU_UTIL" \
    --max-model-len 8192 \
    --dtype half

# 另一个版本（更低 GPU 利用率）
# vllm serve "$MODEL_PATH" \
#     --port 8080 \
#     --host 0.0.0.0 \
#     --served-model-name bge-embedding-m3 \
#     --gpu-memory-utilization 0.1 \
#     --dtype half
