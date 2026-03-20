#!/bin/bash
# ============================================
# Anthropic API 验证脚本
# ============================================

API_KEY="${ANTHROPIC_API_KEY:-REDACTED_ANTHROPIC_API_KEY}"
BASE_URL="${ANTHROPIC_BASE_URL:-https://api.apipro.ai}"
MODEL="${ANTHROPIC_MODEL:-claude-3-5-sonnet-latest}"

echo "========================================"
echo "Anthropic API 验证"
echo "========================================"
echo "模型: $MODEL"
echo "API URL: $BASE_URL"
echo "========================================"

# OpenAI 兼容接口验证
echo ""
echo "测试 OpenAI 兼容接口..."
curl -sS "${BASE_URL}/v1/chat/completions" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{\"role\": \"user\", \"content\": \"hi\"}],
        \"max_tokens\": 16
    }" | jq -r '.choices[0].message.content // .error.message'

echo ""

# Anthropic 原生接口验证
echo "测试 Anthropic 原生接口..."
curl -sS "${BASE_URL}/v1/messages" \
    -H "x-api-key: ${API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"max_tokens\": 16,
        \"messages\": [{\"role\": \"user\", \"content\": \"hi\"}]
    }" | jq -r '.content[0].text // .error.message'

echo ""
