#!/bin/bash
# ============================================
# Infini-AI 项目统一配置
# ============================================

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ----------------------------------------
# 加载环境变量（从 .env 文件）
# ----------------------------------------
ENV_FILE="$PROJECT_ROOT/.env"

if [ -f "$ENV_FILE" ]; then
    # 安全地加载 .env 文件（忽略注释和空行）
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 跳过注释和空行
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        # 只导出有效的 KEY=VALUE 行
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            export "$line" 2>/dev/null || true
        fi
    done < "$ENV_FILE"
    echo "✅ 已加载环境变量: $ENV_FILE"
else
    echo "⚠️  警告: 未找到 .env 文件，请从 .env.example 复制并配置:"
    echo "   cp $PROJECT_ROOT/.env.example $PROJECT_ROOT/.env"
    echo ""
fi

# ----------------------------------------
# 默认配置（可被环境变量覆盖）
# ----------------------------------------

# 无问芯穹 (Infini-AI) 平台
export INFINI_AI_API_KEY="${INFINI_AI_API_KEY:-}"
export INFINI_AI_BASE_URL="${INFINI_AI_BASE_URL:-https://cloud.infini-ai.com/AIStudio/inference/api}"

# 商汤科技 (SenseNova) 平台
export SENSENOVA_API_KEY="${SENSENOVA_API_KEY:-}"
export SENSENOVA_BASE_URL="${SENSENOVA_BASE_URL:-https://api.sensenova.cn/compatible-mode/v2}"

# Anthropic API
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.apipro.ai}"
export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-claude-opus-4-6}"

# 本地模型路径
export METAX_MODEL_PATH="${METAX_MODEL_PATH:-/mnt/public/model/huggingface/metax-tech}"
export AFS_MODEL_PATH="${AFS_MODEL_PATH:-/mnt/afs/models}"
export LOCAL_MODEL_PATH="${LOCAL_MODEL_PATH:-/home/simon/memtensor}"

# ----------------------------------------
# 服务实例映射表（无问芯穹）
# 注意：使用函数而非数组来避免特殊字符问题
# ----------------------------------------

get_instance_id() {
    local model_name="$1"
    case "$model_name" in
        "qwen3-32b")          echo "if-dchmmlq56tr54eho" ;;
        "qwen3-coder-480b")   echo "if-dcifq4pj4uwftgls" ;;
        "qwen3.5-35b")        echo "if-dcmy7jd66fvxst44" ;;
        "qwen3.5-397b")       echo "if-dcnw6nur2qq4tpp7" ;;
        "minimax-m2.5")       echo "if-dcmplhbplrick4xn" ;;
        "kimi-k2.5")          echo "if-dcpdyoccypo6sv7j" ;;
        "glm-5")              echo "if-dcpdrbkahqfbxgfz" ;;
        "bge-embedding")      echo "if-dchjecavz7nujkos" ;;
        "qwen3-embedding")    echo "if-dcn2yymrl7ezdr64" ;;
        "qwen3-reranker")     echo "if-dcn2zohn6nnb75n2" ;;
        *)                    echo "" ;;
    esac
}

# 列出所有可用的模型名称
list_models() {
    echo "qwen3-32b qwen3-coder-480b qwen3.5-35b qwen3.5-397b minimax-m2.5 kimi-k2.5 glm-5 bge-embedding qwen3-embedding qwen3-reranker"
}

# ----------------------------------------
# 本地服务端口映射
# ----------------------------------------

get_local_port() {
    local model="$1"
    case "$model" in
        "bge-m3")           echo "18089" ;;
        "bge-reranker")     echo "18090" ;;
        "qwen3.5-35b")      echo "18089" ;;
        "qwen3-32b")        echo "18088" ;;
        *)                  echo "" ;;
    esac
}

# ----------------------------------------
# 辅助函数
# ----------------------------------------

# 获取无问芯穹完整 URL
get_infini_url() {
    local instance_id="$1"
    echo "${INFINI_AI_BASE_URL}/${instance_id}/v1"
}

# 验证服务通用函数
check_service() {
    local url="$1"
    local key="$2"
    local model="$3"
    
    echo "Testing: $model"
    curl -s "${url}/models" \
        -H "Authorization: Bearer ${key}" \
        -H "Content-Type: application/json" 2>/dev/null | jq -r '.data[]?.id' | head -5
}

# 检查 API Key 是否配置
check_api_key() {
    local name="$1"
    local key="$2"
    if [ -z "$key" ]; then
        echo "⚠️  警告: $name API Key 未配置"
        return 1
    else
        echo "✅ $name API Key 已配置 (${key:0:10}...)"
        return 0
    fi
}

# ----------------------------------------
# 配置加载完成提示
# ----------------------------------------
echo ""
echo "========================================"
echo "Infini-AI 项目配置加载完成"
echo "========================================"
echo ""

# 检查关键配置
check_api_key "无问芯穹" "$INFINI_AI_API_KEY"
check_api_key "商汤科技" "$SENSENOVA_API_KEY"
check_api_key "Anthropic" "$ANTHROPIC_API_KEY"

echo ""
echo "模型路径:"
echo "  - METAX_MODEL_PATH:   $METAX_MODEL_PATH"
echo "  - AFS_MODEL_PATH:     $AFS_MODEL_PATH"
echo "  - LOCAL_MODEL_PATH:   $LOCAL_MODEL_PATH"
echo ""

# 如果缺少关键配置，给出提示
if [ -z "$INFINI_AI_API_KEY" ] && [ -z "$SENSENOVA_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "⚠️  警告: 所有 API Key 都未配置"
    echo "   请编辑 $ENV_FILE 添加您的 API Keys"
    echo ""
fi
