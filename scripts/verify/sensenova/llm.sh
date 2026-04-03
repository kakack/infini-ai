#!/bin/bash
# ============================================
# 商汤科技 (SenseNova) 平台 - LLM 验证脚本
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../config.sh"

API_KEY="$SENSENOVA_API_KEY"
BASE_URL="$SENSENOVA_BASE_URL"

if [ -z "$API_KEY" ]; then
    echo "错误: SENSENOVA_API_KEY 未配置"
    exit 1
fi

declare -A MODELS=(
    ["deepseek-r1"]="DeepSeek-R1-IAAR"
    ["qwen3-32b"]="Qwen3-32B-IAAR"
    ["qwen2.5-72b"]="Qwen2-5-72b-Instruct-IAAR"
)

verify_model() {
    local model_key=$1
    local model_id=$2
    
    echo "========================================"
    echo "验证模型: $model_key ($model_id)"
    echo "========================================"
    
    curl -sS -X POST "${BASE_URL}/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${API_KEY}" \
        -d "{
            \"model\": \"$model_id\",
            \"messages\": [{\"role\": \"user\", \"content\": \"写一首关于春天的诗\"}],
            \"max_tokens\": 500,
            \"temperature\": 0.8,
            \"stream\": false
        }" | jq -r '.choices[0].message.content // .error.message' | head -10
    
    echo ""
}

# 执行验证
case "${1:-all}" in
    deepseek|deepseek-r1)
        verify_model "deepseek-r1" "${MODELS[deepseek-r1]}"
        ;;
    qwen3|qwen3-32b)
        verify_model "qwen3-32b" "${MODELS[qwen3-32b]}"
        ;;
    qwen2.5|qwen2.5-72b)
        verify_model "qwen2.5-72b" "${MODELS[qwen2.5-72b]}"
        ;;
    all)
        for key in "${!MODELS[@]}"; do
            verify_model "$key" "${MODELS[$key]}"
        done
        ;;
    *)
        echo "用法: $0 [deepseek|qwen3|qwen2.5|all]"
        echo ""
        echo "可用模型:"
        for key in "${!MODELS[@]}"; do
            echo "  - $key: ${MODELS[$key]}"
        done
        exit 1
        ;;
esac
