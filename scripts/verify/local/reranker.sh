#!/bin/bash
# ============================================
# 本地 Reranker 服务验证脚本
# ============================================

PORT="${1:-18090}"
URL="http://127.0.0.1:${PORT}"

echo "========================================"
echo "验证本地 Reranker 服务"
echo "服务地址: $URL"
echo "========================================"

# Rerank API
echo ""
echo "测试 Rerank API..."
curl -sS -X POST "${URL}/v1/rerank" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "bge-reranker-v2-m3",
        "query": "What is the capital of France?",
        "documents": [
            "The capital of France is Paris.",
            "The capital of Germany is Berlin."
        ]
    }' | jq -r '.results // .error.message'

# Score API (如果支持)
echo ""
echo "测试 Score API..."
curl -sS -X POST "${URL}/score" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "bge-reranker-v2-m3",
        "text_1": "什么是向量检索？",
        "text_2": "向量检索通过向量相似度在语义空间中查找最相关文本。"
    }' | jq -r '.score // .error.message' 2>/dev/null || echo "Score API 可能不支持"

echo ""
echo "✅ 验证完成"
