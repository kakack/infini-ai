# Infini-AI

在 [Infini-AI](https://cloud.infini-ai.com/) 平台上下发训练和推理任务的脚本记录，同时包含其他平台（商汤、Anthropic）的 API 验证脚本。

## 目录结构

```
.
├── README.md                      # 本文件
├── .env.example                   # 环境变量配置模板（提交到 Git）
├── .env                           # 真实环境变量（⚠️ 不提交到 Git）
├── scripts/                       # 脚本目录
│   ├── config.sh                  # 统一配置加载器
│   ├── deploy/                    # 部署脚本
│   │   ├── local/                 # 本地 vLLM 部署
│   │   │   ├── embedding.sh       # Embedding 模型部署
│   │   │   ├── reranker.sh        # Reranker 模型部署
│   │   │   ├── llm.sh             # LLM 模型部署
│   │   │   └── glm5-2nodes.sh     # GLM-5 双节点部署
│   │   └── platform/              # 平台推理任务脚本
│   │       ├── glm5_2n_vllm.sh
│   │       ├── kimi_k2_5-2n_vllm.sh
│   │       ├── qwen3_5_397b-1n_vllm.sh
│   │       ├── qwen3_5_397b-2n_vllm.sh
│   │       └── qwen3_coder_480b-4n-vllm.sh
│   └── verify/                    # 验证脚本
│       ├── local/                 # 本地服务验证
│       ├── infini-ai/             # 无问芯穹平台验证
│       ├── sensenova/             # 商汤科技平台验证
│       └── anthropic/             # Anthropic API 验证
├── inference/                     # 原有推理脚本（已同步到 scripts/deploy/platform/）
├── training/                      # 训练任务脚本
├── data/                          # 数据文件
└── logs/                          # 运行日志（不纳入版本管理）
```

## 快速开始

### 1. 配置环境变量

```bash
cd ~/Projects/infini-ai

# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，填入您的 API Keys
vim .env
```

`.env` 文件示例：
```bash
# 无问芯穹
INFINI_AI_API_KEY=sk-your-infini-ai-key

# 商汤科技
SENSENOVA_API_KEY=sk-your-sensenova-key

# Anthropic
ANTHROPIC_API_KEY=sk-your-anthropic-key
```

⚠️ **注意**: `.env` 文件包含敏感信息，**请勿提交到 Git**！已配置在 `.gitignore` 中。

### 2. 加载配置

```bash
source scripts/config.sh
```

这将自动加载 `.env` 文件中的配置，并检查 API Keys 是否已正确设置。

### 3. 本地部署

```bash
# 部署 Embedding 模型 (bge-m3)
./scripts/deploy/local/embedding.sh [模型路径] [端口]

# 部署 LLM 模型
./scripts/deploy/local/llm.sh qwen3.5-35b 18089
./scripts/deploy/local/llm.sh qwen3-32b 18088

# 部署 GLM-5 双节点
# 节点 1: RANK=0 ./scripts/deploy/local/glm5-2nodes.sh
# 节点 2: RANK=1 ./scripts/deploy/local/glm5-2nodes.sh
```

### 4. 平台推理任务

```bash
# GLM5 2节点 vLLM 推理
bash scripts/deploy/platform/glm5_2n_vllm.sh

# Qwen3.5-397B 单节点推理
bash scripts/deploy/platform/qwen3_5_397b-1n_vllm.sh

# Kimi-K2.5 2节点推理
bash scripts/deploy/platform/kimi_k2_5-2n_vllm.sh
```

### 5. 服务验证

```bash
# 验证本地服务
./scripts/verify/local/llm.sh 18089 Qwen3.5-35B
./scripts/verify/local/embedding.sh 18089
./scripts/verify/local/reranker.sh 18090

# 验证无问芯穹平台
./scripts/verify/infini-ai/llm.sh all                    # 验证全部模型
./scripts/verify/infini-ai/llm.sh kimi                   # 验证 Kimi-K2.5
./scripts/verify/infini-ai/llm.sh qwen3.5                # 验证 Qwen3.5-35B
./scripts/verify/infini-ai/llm.sh glm                    # 验证 GLM-5
./scripts/verify/infini-ai/embedding.sh                  # 验证 Embedding
./scripts/verify/infini-ai/reranker.sh                   # 验证 Reranker

# 验证商汤科技平台
./scripts/verify/sensenova/llm.sh deepseek               # 验证 DeepSeek-R1
./scripts/verify/sensenova/llm.sh qwen3                  # 验证 Qwen3-32B
./scripts/verify/sensenova/llm.sh all                    # 验证全部

# 验证 Anthropic API
./scripts/verify/anthropic/llm.sh
```

## 支持的模型

### 大语言模型 (LLM)

| 模型 | 平台 | 脚本位置 |
|-----|------|---------|
| **Qwen3-32B** | Infini-AI | `scripts/verify/infini-ai/llm.sh` |
| **Qwen3-Coder-480B** | Infini-AI | `scripts/verify/infini-ai/llm.sh` |
| **Qwen3.5-35B** | Infini-AI/Local | `scripts/verify/infini-ai/llm.sh` / `scripts/deploy/local/llm.sh` |
| **Qwen3.5-397B** | Infini-AI | `scripts/verify/infini-ai/llm.sh` |
| **GLM-5** | Infini-AI/Local | `scripts/verify/infini-ai/llm.sh` / `scripts/deploy/local/glm5-2nodes.sh` |
| **Kimi-K2.5** | Infini-AI | `scripts/verify/infini-ai/llm.sh` |
| **MiniMax-M2.5** | Infini-AI | `scripts/verify/infini-ai/llm.sh` |
| **DeepSeek-R1** | SenseNova | `scripts/verify/sensenova/llm.sh` |
| **Claude-3.5** | Anthropic | `scripts/verify/anthropic/llm.sh` |

### Embedding 模型

| 模型 | 平台 | 脚本位置 |
|-----|------|---------|
| **bge-m3** | Local/Infini-AI | `scripts/deploy/local/embedding.sh` / `scripts/verify/infini-ai/embedding.sh` |
| **qwen3-embedding-4b** | Infini-AI | `scripts/verify/infini-ai/embedding.sh` |

### Reranker 模型

| 模型 | 平台 | 脚本位置 |
|-----|------|---------|
| **bge-reranker-v2-m3** | Local | `scripts/deploy/local/reranker.sh` / `scripts/verify/local/reranker.sh` |
| **qwen3-reranker-4b** | Infini-AI | `scripts/verify/infini-ai/reranker.sh` |

## 配置说明

### 环境变量文件 (`.env`)

项目使用 `.env` 文件管理敏感配置，该文件**不应提交到 Git**。

#### 必需配置

```bash
# 无问芯穹
INFINI_AI_API_KEY=sk-your-infini-ai-key

# 商汤科技
SENSENOVA_API_KEY=sk-your-sensenova-key

# Anthropic
ANTHROPIC_API_KEY=sk-your-anthropic-key
```

#### 可选配置

```bash
# 自定义 API 端点（如不设置则使用默认值）
INFINI_AI_BASE_URL=https://cloud.infini-ai.com/AIStudio/inference/api
SENSENOVA_BASE_URL=https://api.sensenova.cn/compatible-mode/v2
ANTHROPIC_BASE_URL=https://api.apipro.ai
ANTHROPIC_MODEL=claude-opus-4-6

# 自定义模型路径
METAX_MODEL_PATH=/mnt/public/model/huggingface/metax-tech
AFS_MODEL_PATH=/mnt/afs/models
LOCAL_MODEL_PATH=/home/simon/memtensor
```

### 通过环境变量覆盖

您也可以在运行前直接设置环境变量，会覆盖 `.env` 中的值：

```bash
export INFINI_AI_API_KEY="sk-another-key"
source scripts/config.sh
```

## 模型名称对照表

| 常用称呼 | 平台实际名称 | 说明 |
|---------|-------------|------|
| Qwen3-32B | `Qwen3-32B` | 基础模型 |
| Qwen3.5-35B | `Qwen3.5-35B` | MoE 模型 |
| Qwen3.5-397B | `Qwen3.5-397B-A17B-W8A8` | W8A8 量化 |
| GLM-5 | `GLM-5` | 智谱最新模型 |
| Kimi-K2.5 | `Kimi-K2.5` | 月之暗面 |
| BGE-M3 | `bge-m3` / `bge-embedding-m3` | Embedding |
| Qwen3-Embedding | `qwen3-embedding-4b` | 阿里 Embedding |

## 硬件要求

### GLM-5 (双节点)
- 2 Nodes × 8 卡 沐曦 C500
- TP=4, DP=4
- 显存: 512GB (64GB × 8)

### Qwen3.5-397B (单节点)
- 8 卡 沐曦 C500
- W8A8 量化
- 显存: 512GB+

## 日志查看

```bash
# 平台推理日志
tail -f logs/error_<script_name>.log

# 本地部署日志
# 日志默认输出到控制台，可重定向到文件
./scripts/deploy/local/llm.sh qwen3.5-35b > logs/qwen3.5_deploy.log 2>&1
```

## 安全提示

⚠️ **永远不要将 `.env` 文件提交到 Git！**

- `.env` 已配置在 `.gitignore` 中
- 只提交 `.env.example` 作为配置模板
- 如果意外提交了包含密钥的文件，请立即：
  1. 撤销提交：`git reset --soft HEAD~1`
  2. 轮换（revoke）相关 API Keys
  3. 重新提交清理后的代码

## 开发指南

### 添加新脚本

1. 根据功能选择目录 (`scripts/deploy/` 或 `scripts/verify/`)
2. 从 `scripts/config.sh` 加载配置：`source "$(dirname "$0")/../config.sh"`
3. 使用环境变量而非硬编码密钥
4. 确保脚本具有可执行权限：`chmod +x script.sh`

### 示例脚本模板

```bash
#!/bin/bash
source "$(dirname "$0")/../config.sh"

# 检查 API Key
if [ -z "$INFINI_AI_API_KEY" ]; then
    echo "错误: INFINI_AI_API_KEY 未设置"
    exit 1
fi

# 使用配置
curl -H "Authorization: Bearer $INFINI_AI_API_KEY" \
     "$INFINI_AI_BASE_URL/..."
```

## License

MIT
