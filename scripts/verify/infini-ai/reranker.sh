#!/bin/bash
# ============================================
# 无问芯穹平台 - Reranker 模型验证脚本
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../config.sh"

if [ -z "$INFINI_AI_API_KEY" ]; then
    echo "错误: INFINI_AI_API_KEY 未配置"
    exit 1
fi

BASE_URL="$INFINI_AI_BASE_URL"

verify_qwen_reranker() {
    echo "========================================"
    echo "验证 Qwen3-Reranker-4B"
    echo "========================================"
    
    local instance_id
    instance_id=$(get_instance_id "qwen3-reranker")
    
    curl -sS -X POST "${BASE_URL}/${instance_id}/v1/rerank" \
        -H "Authorization: Bearer ${INFINI_AI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "qwen3-reranker-4b",
            "query": "什么是重力？",
            "documents": [
                "重力是一种力，使物体相互吸引。",
                "光速是真空中的常数。",
                "牛顿发现了万有引力。"
            ]
        }' | jq -r '.results // .error.message' 2>/dev/null
    
    echo ""
}

verify_qwen_reranker
