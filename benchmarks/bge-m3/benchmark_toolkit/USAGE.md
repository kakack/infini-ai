# 快速使用指南

## 1. 安装依赖

```bash
pip install requests
```

## 2. 准备测试数据

从业务日志中提取查询文本，保存为 JSONL 格式：

```bash
# queries_1k.jsonl (示例)
{"query": "什么是机器学习"}
{"query": "如何学习Python编程"}
...
```

## 3. 单服务压测

```bash
python3 benchmark.py \
  --url http://your-host:port/v1/embeddings \
  --model bge-m3 \
  --dataset /path/to/queries.jsonl \
  --concurrency 1,8,16,64 \
  --requests 2000 \
  --output results.json
```

## 4. 双服务对比

分别测试两个服务：

```bash
# 测试服务1
python3 benchmark.py --url http://host1:18000/v1/embeddings \
  --model bge-m3 --dataset queries.jsonl \
  --concurrency 1,8,16,64 --requests 2000 \
  --output service1.json

# 测试服务2
python3 benchmark.py --url http://host2:28076/v1/embeddings \
  --model bge-m3 --dataset queries.jsonl \
  --concurrency 1,8,16,64 --requests 2000 \
  --output service2.json

# 对比结果
python3 compare.py service1.json service2.json
```

## 5. 解读结果

关键指标：
- **P50 E2E**: 中位数延迟，越低越好
- **Throughput**: 吞吐量，越高越好
- **Success Rate**: 成功率，应接近 100%

## 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--url` | API 端点地址 | 必填 |
| `--model` | 模型名称 | bge-m3 |
| `--dataset` | 数据集路径 (JSONL) | 必填 |
| `--concurrency` | 并发度 (逗号分隔) | 1,8,16,64 |
| `--requests` | 每轮请求数 | 2000 |
| `--timeout` | 请求超时 (秒) | 60 |
| `--output` | 输出文件 | results.json |
