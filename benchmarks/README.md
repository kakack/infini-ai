# Benchmarks - 模型性能压测

本目录包含模型性能压测相关脚本和结果。

## 目录结构

```
benchmarks/
├── README.md                  # 本文件
├── benchmark_configs.py       # 服务配置列表（URL + model name）
├── run_benchmark.py           # 标准化压测入口脚本
└── bge-m3/                    # BGE-M3 压测专项
    ├── benchmark_toolkit/     # 核心压测工具包
    │   ├── benchmark.py       # 核心压测脚本
    │   ├── compare.py         # 双服务对比分析
    │   ├── README.md          # 压测工具使用说明
    │   └── USAGE.md           # 详细用法文档
    ├── bge_m3_3service_comparison.md  # 三服务对比报告
    └── bge_m3_service3_results.json   # Service 3 原始数据
```

## 快速开始

```bash
cd benchmarks

# 查看可用服务配置
python3 run_benchmark.py --list-services

# 测试指定服务
python3 run_benchmark.py --service Service3

# 测试所有配置的服务
python3 run_benchmark.py --all-services
```

## BGE-M3 压测报告

| 服务 | URL | 最佳吞吐量 | 平均 P50 延迟 |
|------|-----|-----------|--------------|
| Service 1 | localhost:18000 | 16.08 req/s | 270.6 ms |
| Service 2 | localhost:28076 | 16.33 req/s | 228.0 ms |
| **Service 3** | 106.75.235.231:58089 | **17.85 req/s** | **200.4 ms** |

**结论**: Service 3 在吞吐量和延迟上均表现最优。

完整报告见: [bge-m3/bge_m3_3service_comparison.md](bge-m3/bge_m3_3service_comparison.md)
