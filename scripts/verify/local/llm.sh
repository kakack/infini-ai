#!/bin/bash
# ============================================
# 本地 LLM 服务验证脚本
# ============================================

PORT="${1:-18089}"
MODEL="${2:-Qwen3.5-35B}"
URL="http://127.0.0.1:${PORT}"

echo "========================================"
echo "验证本地 LLM 服务"
echo "服务地址: $URL"
echo "模型: $MODEL"
echo "========================================"

# 列出可用模型
echo ""
echo "可用模型:"
curl -sS "${URL}/v1/models" | jq -r '.data[].id' 2>/dev/null || echo "无法获取模型列表"

# 简单对话
echo ""
echo "测试对话..."
curl -sS -X POST "${URL}/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d "{
        \"model\":\"$MODEL\",
        \"messages\":[{\"role\":\"user\",\"content\":\"你好，请介绍一下你自己\"}],
        \"max_tokens\":128
    }" | jq -r '.choices[0].message.content // .error.message'

echo ""
echo "✅ 验证完成"
