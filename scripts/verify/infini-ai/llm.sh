#!/bin/bash
# ============================================
# 无问芯穹平台 - LLM 模型验证脚本
# ============================================

# 加载配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../config.sh"

# 检查 API Key
if [ -z "$INFINI_AI_API_KEY" ]; then
    echo "错误: INFINI_AI_API_KEY 未配置"
    echo "请在 .env 文件中设置"
    exit 1
fi

BASE_URL="$INFINI_AI_BASE_URL"

# 定义模型列表
MODELS=(
    "qwen3-32b:Qwen3-32B"
    "qwen3-coder-480b:Qwen3-Coder-480B"
    "qwen3.5-35b:Qwen3.5-35B"
    "qwen3.5-397b:Qwen3.5-397B-A17B-W8A8"
    "minimax-m2.5:MiniMax-M2.5"
    "kimi-k2.5:Kimi-K2.5"
    "glm-5:GLM-5"
)

verify_model() {
    local model_key="$1"
    local model_id="$2"
    local instance_id
    instance_id=$(get_instance_id "$model_key")
    
    if [ -z "$instance_id" ]; then
        echo "错误: 未知模型 $model_key"
        return 1
    fi
    
    echo "========================================"
    echo "验证模型: $model_key"
    echo "模型 ID: $model_id"
    echo "实例 ID: $instance_id"
    echo "========================================"
    
    curl -sS -X POST "${BASE_URL}/${instance_id}/v1/chat/completions" \
        -H "Authorization: Bearer ${INFINI_AI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model_id\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Hello, verify this service is working.\"}],
            \"max_tokens\": 100,
            \"stream\": false
        }" | jq -r '.choices[0].message.content // .error.message' 2>/dev/null | head -5
    
    echo ""
}

# 显示帮助
show_help() {
    echo "用法: $0 [模型名|all]"
    echo ""
    echo "可用模型:"
    for model in "${MODELS[@]}"; do
        local key=${model%%:*}
        local id=${model##*:}
        echo "  - $key: $id"
    done
    echo ""
    echo "示例:"
    echo "  $0 all          # 验证全部模型"
    echo "  $0 kimi         # 验证 Kimi-K2.5"
    echo "  $0 glm          # 验证 GLM-5"
}

# 主逻辑
case "${1:-all}" in
    qwen3|qwen3-32b)
        verify_model "qwen3-32b" "Qwen3-32B"
        ;;
    coder|qwen3-coder)
        verify_model "qwen3-coder-480b" "Qwen3-Coder-480B"
        ;;
    qwen3.5|qwen3.5-35b)
        verify_model "qwen3.5-35b" "Qwen3.5-35B"
        ;;
    qwen3.5-397b|397b)
        verify_model "qwen3.5-397b" "Qwen3.5-397B-A17B-W8A8"
        ;;
    minimax|minimax-m2.5)
        verify_model "minimax-m2.5" "MiniMax-M2.5"
        ;;
    kimi|kimi-k2.5)
        verify_model "kimi-k2.5" "Kimi-K2.5"
        ;;
    glm|glm-5)
        verify_model "glm-5" "GLM-5"
        ;;
    all)
        verify_model "kimi-k2.5" "Kimi-K2.5"
        verify_model "glm-5" "GLM-5"
        verify_model "qwen3.5-35b" "Qwen3.5-35B"
        verify_model "qwen3-32b" "Qwen3-32B"
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
esac
