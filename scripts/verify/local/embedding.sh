#!/bin/bash
# ============================================
# 本地 Embedding 服务验证脚本
# ============================================

PORT="${1:-18089}"
URL="http://127.0.0.1:${PORT}"

echo "========================================"
echo "验证本地 Embedding 服务"
echo "服务地址: $URL"
echo "========================================"

# 单个文本
echo ""
echo "测试单个文本 embedding..."
curl -sS "${URL}/v1/embeddings" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "bge-m3",
        "input": "Hello vLLM"
    }' | jq -r '.data[0].embedding[0:3] // .error.message'

# 批量文本
echo ""
echo "测试批量文本 embedding..."
curl -sS "${URL}/v1/embeddings" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "bge-m3",
        "input": ["今天天气不错", "I love retrieval systems"]
    }' | jq -r '.data | length'

echo ""
echo "✅ 验证完成"
