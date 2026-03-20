#!/bin/bash
# ============================================
# 大语言模型本地部署脚本
# 支持模型: Qwen3.5-35B, Qwen3-32B
# ============================================

set -e

# 默认参数
MODEL_NAME="${1:-qwen3.5-35b}"  # 可选: qwen3.5-35b, qwen3-32b
PORT="${2:-18089}"

# 模型路径配置
declare -A MODEL_PATHS=(
    ["qwen3.5-35b"]="/home/simon/memtensor/Qwen3.5-35B-A3B"
    ["qwen3-32b"]="/home/simon/memtensor/metax-tech/Qwen3-32B.w8a8"
)

MODEL_PATH="${MODEL_PATHS[$MODEL_NAME]}"
if [ -z "$MODEL_PATH" ]; then
    echo "错误: 未知模型 $MODEL_NAME"
    echo "可用模型: ${!MODEL_PATHS[@]}"
    exit 1
fi

echo "========================================"
echo "部署 LLM 模型: $MODEL_NAME"
echo "========================================"
echo "模型路径: $MODEL_PATH"
echo "服务端口: $PORT"
echo "========================================"

VLLM_PLUGINS='' DISABLE_MODEL_SOURCE_CHECK=True \
vllm serve "$MODEL_PATH" \
    --host 0.0.0.0 \
    --port "$PORT" \
    --served-model-name "$MODEL_NAME" \
    --gpu-memory-utilization 0.70 \
    --max-model-len 16384
