#!/bin/bash
# ============================================
# 无问芯穹平台 - Embedding 模型验证脚本
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../config.sh"

if [ -z "$INFINI_AI_API_KEY" ]; then
    echo "错误: INFINI_AI_API_KEY 未配置"
    exit 1
fi

BASE_URL="$INFINI_AI_BASE_URL"

verify_bge_embedding() {
    echo "========================================"
    echo "验证 BGE-Embedding-M3"
    echo "========================================"
    
    local instance_id
    instance_id=$(get_instance_id "bge-embedding")
    
    curl -sS -X POST "${BASE_URL}/${instance_id}/v1/embeddings" \
        -H "Authorization: Bearer ${INFINI_AI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "bge-embedding-m3",
            "input": ["hello world", "验证服务是否可用"]
        }' | jq -r '.data[0].embedding[0:3] // .error.message' 2>/dev/null
    
    echo ""
}

verify_qwen_embedding() {
    echo "========================================"
    echo "验证 Qwen3-Embedding-4B"
    echo "========================================"
    
    local instance_id
    instance_id=$(get_instance_id "qwen3-embedding")
    
    curl -sS -X POST "${BASE_URL}/${instance_id}/v1/embeddings" \
        -H "Authorization: Bearer ${INFINI_AI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "qwen3-embedding-4b",
            "input": "验证 embedding 服务"
        }' | jq -r '.data[0].embedding[0:3] // .error.message' 2>/dev/null
    
    echo ""
}

# 执行验证
case "${1:-all}" in
    bge)
        verify_bge_embedding
        ;;
    qwen)
        verify_qwen_embedding
        ;;
    all)
        verify_bge_embedding
        verify_qwen_embedding
        ;;
    *)
        echo "用法: $0 [bge|qwen|all]"
        exit 1
        ;;
esac
