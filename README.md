# Infini-AI 项目

在 [Infini-AI](https://cloud.infini-ai.com/) 平台上下发训练和推理任务的脚本记录，同时包含其他平台（商汤、Anthropic）的 API 验证脚本。

## 目录结构

```
.
├── README.md                          # 本文件（项目说明）
├── .env.example                       # 环境变量配置模板
├── .env                               # 真实环境变量（⚠️ 不提交到 Git）
│
├── scripts/                           # 脚本目录
│   ├── config.sh                      # 统一配置加载器（API Keys、模型映射）
│   ├── deploy/                        # 部署脚本
│   │   ├── local/                     # 本地 vLLM 部署
│   │   │   ├── embedding.sh           # Embedding 模型部署 (bge-m3)
│   │   │   ├── reranker.sh            # Reranker 模型部署 (bge-reranker-v2-m3)
│   │   │   ├── llm.sh                 # LLM 模型部署 (Qwen系列)
│   │   │   └── glm5-2nodes.sh         # GLM-5 双节点部署
│   │   └── platform/                  # 平台推理任务脚本（无问芯穹）
│   │       ├── glm5_2n_vllm.sh        # GLM-5 双节点
│   │       ├── kimi_k2_5-2n_vllm.sh   # Kimi-K2.5 双节点
│   │       ├── qwen3_5_397b-1n_vllm.sh
│   │       ├── qwen3_5_397b-2n_vllm.sh
│   │       └── qwen3_coder_480b-4n-vllm.sh
│   │
│   └── verify/                        # 验证脚本
│       ├── local/                     # 本地服务验证
│       │   ├── embedding.sh           # 验证本地 Embedding
│       │   ├── reranker.sh            # 验证本地 Reranker
│       │   └── llm.sh                 # 验证本地 LLM
│       ├── infini-ai/                 # 无问芯穹平台验证
│       │   ├── llm.sh                 # 验证平台 LLM 服务
│       │   ├── embedding.sh           # 验证平台 Embedding
│       │   └── reranker.sh            # 验证平台 Reranker
│       ├── sensenova/                 # 商汤科技平台验证
│       │   └── llm.sh                 # 验证商汤 LLM
│       └── anthropic/                 # Anthropic API 验证
│           └── llm.sh
│

├── inference/                         # 旧版推理脚本（已迁移到 scripts/deploy/platform/）
│   ├── glm5_2n_vllm.sh
│   ├── qwen3_5_397b-1n_vllm.sh
│   └── ...
│
├── benchmarks/                        # 性能压测相关
│   ├── benchmark_configs.py           # 压测服务配置列表
│   ├── run_benchmark.py               # 标准化压测入口脚本
│   └── bge-m3/                        # BGE-M3 压测专项
│       ├── benchmark_toolkit/         # 核心压测工具
│       │   ├── benchmark.py
│       │   ├── compare.py
│       │   ├── README.md
│       │   └── USAGE.md
│       ├── bge_m3_3service_comparison.md  # 三服务对比报告
│       └── bge_m3_service3_results.json   # Service 3 原始数据
│
├── data/                              # 测试数据
│   ├── queries_1k.jsonl               # 短文本测试集 (~292 chars)
│   ├── queries_4k.jsonl               # 中等文本测试集 (~876 chars)
│   └── queries_8k.jsonl               # 长文本测试集 (~1918 chars)
│
└── logs/                              # 运行日志（不纳入版本管理）
```

---

## 快速开始

### 1. 配置环境变量

```bash
cd ~/Projects/infini-ai

# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，填入您的 API Keys
vim .env
```

### 2. 加载配置

```bash
source scripts/config.sh
```

---

## 🚀 本地部署（Inference）

### Embedding 模型部署

```bash
# 默认: 模型路径 /home/simon/memtensor/bge-m3, 端口 18089
./scripts/deploy/local/embedding.sh

# 自定义路径和端口
./scripts/deploy/local/embedding.sh /path/to/bge-m3 8080

# 完整命令示例（复制粘贴到终端）：
# vllm serve /home/simon/memtensor/bge-m3 \
#     --host 0.0.0.0 \
#     --port 18089 \
#     --served-model-name bge-m3 \
#     --gpu-memory-utilization 0.08 \
#     --max-model-len 8192 \
#     --dtype half
```

### LLM 模型部署

```bash
# 部署 Qwen3.5-35B（默认端口 18089）
./scripts/deploy/local/llm.sh qwen3.5-35b

# 部署 Qwen3-32B（指定端口 18088）
./scripts/deploy/local/llm.sh qwen3-32b 18088

# 完整命令示例（Qwen3.5-35B）：
# VLLM_PLUGINS='' DISABLE_MODEL_SOURCE_CHECK=True \
# vllm serve /home/simon/memtensor/Qwen3.5-35B-A3B \
#     --host 0.0.0.0 \
#     --port 18089 \
#     --served-model-name qwen3.5-35b \
#     --gpu-memory-utilization 0.70 \
#     --max-model-len 16384
```

### Reranker 模型部署

```bash
# 默认: GPU 1, 端口 18090, GPU 利用率 0.3
./scripts/deploy/local/reranker.sh

# 指定 GPU 0 和端口 8090
./scripts/deploy/local/reranker.sh /home/simon/memtensor/bge-reranker-v2-m3 8090 0 0.1

# 完整命令示例：
# CUDA_VISIBLE_DEVICES=1 python -m vllm.entrypoints.openai.api_server \
#     --model=/home/simon/memtensor/bge-reranker-v2-m3 \
#     --tensor-parallel-size 1 \
#     --gpu-memory-utilization 0.3 \
#     --dtype half \
#     --served-model-name "bge-reranker-v2-m3" \
#     --host 0.0.0.0 \
#     --port 18090
```

### GLM-5 双节点部署

```bash
# 节点 1 (Rank 0)
RANK=0 MASTER_ADDR=10.201.45.145 WORLD_SIZE=2 ./scripts/deploy/local/glm5-2nodes.sh

# 节点 2 (Rank 1)
RANK=1 MASTER_ADDR=10.201.45.145 WORLD_SIZE=2 ./scripts/deploy/local/glm5-2nodes.sh

# 关键参数说明：
# - TP=4 (Tensor Parallel)
# - DP=4 (Data Parallel)
# - 每节点 8 卡沐曦 C500
# - 服务端口: 8089 (仅主节点)
```

---

## ☁️ 平台推理任务（Platform Inference）

### 无问芯穹平台任务脚本

```bash
# GLM-5 双节点 vLLM 推理
bash scripts/deploy/platform/glm5_2n_vllm.sh

# Kimi-K2.5 双节点推理
bash scripts/deploy/platform/kimi_k2_5-2n_vllm.sh

# Qwen3.5-397B 单节点推理
bash scripts/deploy/platform/qwen3_5_397b-1n_vllm.sh

# Qwen3.5-397B 双节点推理
bash scripts/deploy/platform/qwen3_5_397b-2n_vllm.sh

# Qwen3-Coder-480B 四节点推理
bash scripts/deploy/platform/qwen3_coder_480b-4n-vllm.sh
```

---

## ✅ 服务验证（Verify）

### 本地服务验证

```bash
# 验证 LLM 服务（默认端口 18089）
./scripts/verify/local/llm.sh
./scripts/verify/local/llm.sh 18089 Qwen3.5-35B

# 验证 Embedding 服务
./scripts/verify/local/embedding.sh
./scripts/verify/local/embedding.sh 18089

# 验证 Reranker 服务
./scripts/verify/local/reranker.sh
./scripts/verify/local/reranker.sh 18090

# 手动验证命令示例（复制粘贴）：
# curl http://127.0.0.1:18089/v1/models | jq
# curl -X POST http://127.0.0.1:18089/v1/chat/completions \
#     -H 'Content-Type: application/json' \
#     -d '{"model":"Qwen3.5-35B","messages":[{"role":"user","content":"你好"}]}'
```

### 无问芯穹平台验证

```bash
# 验证全部 LLM 模型
./scripts/verify/infini-ai/llm.sh all

# 验证指定模型
./scripts/verify/infini-ai/llm.sh kimi        # Kimi-K2.5
./scripts/verify/infini-ai/llm.sh glm         # GLM-5
./scripts/verify/infini-ai/llm.sh qwen3.5     # Qwen3.5-35B
./scripts/verify/infini-ai/llm.sh qwen3       # Qwen3-32B
./scripts/verify/infini-ai/llm.sh coder       # Qwen3-Coder-480B
./scripts/verify/infini-ai/llm.sh minimax     # MiniMax-M2.5
./scripts/verify/infini-ai/llm.sh 397b        # Qwen3.5-397B

# 验证 Embedding 服务
./scripts/verify/infini-ai/embedding.sh       # 全部
./scripts/verify/infini-ai/embedding.sh bge   # 仅 BGE-M3
./scripts/verify/infini-ai/embedding.sh qwen  # 仅 Qwen3-Embedding

# 验证 Reranker 服务
./scripts/verify/infini-ai/reranker.sh

# 手动验证命令示例（需要 API Key）：
# curl -X POST https://cloud.infini-ai.com/AIStudio/inference/api/<instance_id>/v1/chat/completions \
#     -H "Authorization: Bearer $INFINI_AI_API_KEY" \
#     -H "Content-Type: application/json" \
#     -d '{"model":"Kimi-K2.5","messages":[{"role":"user","content":"Hello"}]}'
```

### 商汤科技平台验证

```bash
# 验证全部模型
./scripts/verify/sensenova/llm.sh all

# 验证指定模型
./scripts/verify/sensenova/llm.sh deepseek    # DeepSeek-R1
./scripts/verify/sensenova/llm.sh qwen3       # Qwen3-32B
```

### Anthropic API 验证

```bash
./scripts/verify/anthropic/llm.sh
```

---

## 📊 BGE-M3 性能压测

### 快速压测

```bash
cd benchmarks

# 列出可用服务配置
python3 run_benchmark.py --list-services
python3 run_benchmark.py --list-datasets

# 测试单个服务（全部数据集）
python3 run_benchmark.py --service Service3

# 测试单个服务（指定数据集）
python3 run_benchmark.py --service Service3 --dataset 1k,4k

# 批量测试所有配置的服务
python3 run_benchmark.py --all-services

# 测试自定义 URL
python3 run_benchmark.py --url http://host:port/v1/embeddings --model bge-m3
```

### 使用底层工具

```bash
cd benchmarks/bge-m3/benchmark_toolkit

# 单服务压测
python3 benchmark.py \
  --url http://106.75.235.231:58089/v1/embeddings \
  --model bge-m3 \
  --dataset ../../data/queries_1k.jsonl \
  --concurrency 1,8,16,64 \
  --requests 2000 \
  --output results.json

# 双服务对比
python3 compare.py service1_results.json service2_results.json
```

---

## 🏋️ 训练任务（Training）

```bash
# 训练脚本目录结构（待扩展）
training/
├── README.md              # 训练任务说明
├── prepare_data.sh        # 数据预处理
├── train.sh               # 启动训练
└── configs/               # 训练配置
    ├── sft.yaml
    └── dpo.yaml

# 启动训练示例（待补充）
# bash training/train.sh --config configs/sft.yaml
```

---

## 🔧 配置说明

### 环境变量文件 (`.env`)

```bash
# 无问芯穹
INFINI_AI_API_KEY=sk-your-infini-ai-key
INFINI_AI_BASE_URL=https://cloud.infini-ai.com/AIStudio/inference/api

# 商汤科技
SENSENOVA_API_KEY=sk-your-sensenova-key

# Anthropic
ANTHROPIC_API_KEY=sk-your-anthropic-key

# 本地模型路径（可选）
LOCAL_MODEL_PATH=/home/simon/memtensor
METAX_MODEL_PATH=/mnt/public/model/huggingface/metax-tech
AFS_MODEL_PATH=/mnt/afs/models
```

### 模型名称映射

| 常用称呼 | 平台实际名称 | 实例 ID |
|---------|-------------|---------|
| Qwen3-32B | `Qwen3-32B` | `if-dchmmlq56tr54eho` |
| Qwen3.5-35B | `Qwen3.5-35B` | `if-dcmy7jd66fvxst44` |
| Qwen3.5-397B | `Qwen3.5-397B-A17B-W8A8` | `if-dcnw6nur2qq4tpp7` |
| GLM-5 | `GLM-5` | `if-dcpdrbkahqfbxgfz` |
| Kimi-K2.5 | `Kimi-K2.5` | `if-dcpdyoccypo6sv7j` |
| BGE-M3 | `bge-embedding-m3` | `if-dchjecavz7nujkos` |

---

## 📝 开发指南

### 添加新的验证脚本

```bash
# 1. 创建脚本
touch scripts/verify/<platform>/new_service.sh
chmod +x scripts/verify/<platform>/new_service.sh

# 2. 加载统一配置
source "$(dirname "$0")/../../config.sh"

# 3. 使用环境变量而非硬编码密钥
curl -H "Authorization: Bearer $INFINI_AI_API_KEY" ...
```

### 添加压测服务配置

编辑 `benchmarks/benchmark_configs.py`：

```python
SERVICES = [
    {
        "name": "Service 4",
        "url": "http://new-host:port/v1/embeddings",
        "model": "bge-m3",
        "description": "新服务",
        "tested_at": "2025-04-03"
    },
    # ... 原有配置
]
```

---

## 📚 相关文档

| 文档 | 说明 |
|------|------|
| `benchmarks/bge-m3/benchmark_toolkit/README.md` | 压测工具详细使用说明 |
| `benchmarks/bge-m3/benchmark_toolkit/USAGE.md` | 压测工具进阶用法 |
| `benchmarks/bge-m3/bge_m3_3service_comparison.md` | 三服务性能对比报告 |
| `benchmarks/bge-m3/bge_m3_service3_results.json` | Service 3 压测原始数据 |

---

## ⚠️ 安全提示

**永远不要将 `.env` 文件提交到 Git！**

- `.env` 已配置在 `.gitignore` 中
- 只提交 `.env.example` 作为配置模板
- 如果意外提交了包含密钥的文件，立即轮换（revoke）相关 API Keys

---

## License

MIT
