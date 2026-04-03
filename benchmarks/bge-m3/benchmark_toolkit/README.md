# bge-m3 / Embedding Model 压测工具包

用于复现 bge-m3 embedding 服务的性能压测测试。

## 📦 包含文件

| 文件 | 说明 |
|------|------|
| `benchmark.py` | 核心压测脚本 |
| `compare.py` | 双服务对比分析脚本 |
| `sample_data/` | 示例数据集（可选） |
| `README.md` | 使用文档 |

## 🔧 环境要求

- Python 3.7+
- requests 库 (`pip install requests`)

## 📊 测试数据格式

JSONL 格式，每行一个 JSON 对象：
```json
{"query": "这里是测试文本内容..."}
{"query": "第二条测试文本..."}
```

## 🚀 使用方法

### 1. 单服务压测

```bash
python3 benchmark.py \
  --url http://106.75.235.231:18000/v1/embeddings \
  --model bge-m3 \
  --dataset /path/to/queries_1k.jsonl \
  --concurrency 1,8,16,64 \
  --requests 2000 \
  --output service1_results.json
```

参数说明：
- `--url`: API 端点地址
- `--model`: 模型名称
- `--dataset`: 测试数据集路径（JSONL 格式）
- `--concurrency`: 并发度（逗号分隔）
- `--requests`: 每个并发度的请求数
- `--timeout`: 单个请求超时时间（秒）
- `--output`: 结果输出文件

### 2. 双服务对比

分别测试两个服务：

```bash
# 测试 Service 1
python3 benchmark.py \
  --url http://106.75.235.231:18000/v1/embeddings \
  --model bge-m3 \
  --dataset queries_8k.jsonl \
  --concurrency 1,8,16,64 \
  --requests 2000 \
  --output service1.json

# 测试 Service 2
python3 benchmark.py \
  --url http://106.75.235.231:28076/v1/embeddings \
  --model bge-m3 \
  --dataset queries_8k.jsonl \
  --concurrency 1,8,16,64 \
  --requests 2000 \
  --output service2.json
```

生成对比报告：
```bash
python3 compare.py service1.json service2.json
```

## 📈 输出指标

- **E2E Time**: 端到端延迟（P50/P90/P99）
- **TTFT**: 首 token 时间（P50/P90/P99）
- **Throughput**: 吞吐量（请求/秒）
- **Success Rate**: 成功率

## 📝 示例输出

```
================================================================================
BENCHMARK REPORT
================================================================================

【concurrency_1】
  Success: 2000/2000 (100.00%)
  Total Time: 124.5s
  Throughput: 16.08 req/s
  E2E Time (ms): P50=50.11, P90=128.43, P99=157.40
  TTFT (ms): P50=49.61, P90=127.85, P99=156.92

【concurrency_8】
  Success: 2000/2000 (100.00%)
  Total Time: 20.3s
  Throughput: 98.76 req/s
  E2E Time (ms): P50=68.02, P90=145.78, P99=176.39
  ...
```

## 🔍 常见问题

### Q1: 如何准备测试数据？
从业务日志中提取 query，保存为 JSONL 格式：
```bash
# 每行一个 JSON
{"query": "用户查询内容"}
```

### Q2: 并发度如何选择？
建议: `1,8,16,64`，覆盖从单用户到高并发的场景。

### Q3: 测试需要多长时间？
- 2000 请求 × 4 并发度 = 约 5-10 分钟（取决于服务性能）

### Q4: 如何解读 P50/P90/P99？
- **P50**: 中位数，50% 请求在此时间内完成
- **P90**: 90% 请求在此时间内完成
- **P99**: 99% 请求在此时间内完成（长尾延迟）

## 📊 历史测试结果参考

### Service 1 (106.75.235.231:18000) vs Service 2 (106.75.235.231:28076)

| 数据集 | 并发 | S1 P50 | S2 P50 | 推荐 |
|--------|------|--------|--------|------|
| 1k (短) | 1 | 50ms | 49ms | 相当 |
| 8k (长) | 16 | 265ms | 169ms | **S2** |
| 8k (长) | 64 | 1055ms | 582ms | **S2** |

**结论**: Service 2 更适合长文本和高并发场景。

## 📄 License

MIT License
