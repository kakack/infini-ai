#!/bin/bash
# ============================================
# Reranker 模型本地部署脚本
# 支持模型: bge-reranker-v2-m3
# ============================================

set -e

# 配置
MODEL_PATH="${1:-/home/simon/memtensor/bge-reranker-v2-m3}"
PORT="${2:-18090}"
GPU_ID="${3:-1}"
GPU_UTIL="${4:-0.3}"

echo "========================================"
echo "部署 Reranker 模型"
echo "========================================"
echo "模型路径: $MODEL_PATH"
echo "服务端口: $PORT"
echo "GPU ID: $GPU_ID"
echo "GPU 利用率: $GPU_UTIL"
echo "========================================"

CUDA_VISIBLE_DEVICES=$GPU_ID python -m vllm.entrypoints.openai.api_server \
    --model="$MODEL_PATH" \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization "$GPU_UTIL" \
    --dtype half \
    --served-model-name "bge-reranker-v2-m3" \
    --host 0.0.0.0 \
    --port "$PORT"

# 其他配置示例:
# GPU 0, 端口 8090, 利用率 0.1
# CUDA_VISIBLE_DEVICES=0 \
# python -m vllm.entrypoints.openai.api_server \
#     --model "/home/ubuntu/kyrie/models/bge-reranker-v2-m3" \
#     --served-model-name bge-reranker-v2-m3 \
#     --port 8090 \
#     --host 0.0.0.0 \
#     --gpu-memory-utilization 0.1 \
#     --dtype half
