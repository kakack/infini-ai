#!/usr/bin/env python3
"""
BGE-M3 压测服务配置

历史测试过的服务配置列表，方便复用
"""

# 服务配置列表
SERVICES = [
    {
        "name": "Service 1",
        "url": "http://localhost:18000/v1/embeddings",  # 原 18000 端口
        "model": "bge-m3",
        "description": "原始服务 1",
        "tested_at": "2025-03-31"
    },
    {
        "name": "Service 2", 
        "url": "http://localhost:28076/v1/embeddings",  # 原 28076 端口
        "model": "bge-m3",
        "description": "原始服务 2",
        "tested_at": "2025-03-31"
    },
    {
        "name": "Service 3",
        "url": "http://106.75.235.231:58089/v1/embeddings",
        "model": "bge-m3",
        "description": "新测试服务 - 性能最优",
        "tested_at": "2025-04-02"
    },
]

# 数据集配置
DATASETS = {
    "1k": {
        "path": "data/queries_1k.jsonl",
        "avg_length": 292,
        "description": "短文本 (~292 chars)"
    },
    "4k": {
        "path": "data/queries_4k.jsonl", 
        "avg_length": 876,
        "description": "中等文本 (~876 chars)"
    },
    "8k": {
        "path": "data/queries_8k.jsonl",
        "avg_length": 1918,
        "description": "长文本 (~1918 chars)"
    }
}

# 标准测试配置
BENCHMARK_CONFIG = {
    "concurrency_levels": [1, 8, 16, 64],
    "requests_per_test": 2000,
    "timeout": 60
}


def get_service_by_name(name: str) -> dict:
    """根据名称获取服务配置"""
    for svc in SERVICES:
        if svc["name"].lower() == name.lower() or svc["name"].lower().replace(" ", "") == name.lower().replace(" ", ""):
            return svc
    return None


def get_service_by_url(url: str) -> dict:
    """根据 URL 获取服务配置"""
    for svc in SERVICES:
        if svc["url"] == url:
            return svc
    return None


def list_services():
    """列出所有可用服务"""
    print("="*80)
    print("可用服务列表")
    print("="*80)
    for i, svc in enumerate(SERVICES, 1):
        print(f"\n[{i}] {svc['name']}")
        print(f"    URL: {svc['url']}")
        print(f"    Model: {svc['model']}")
        print(f"    描述: {svc['description']}")
        print(f"    测试时间: {svc['tested_at']}")
    print("\n" + "="*80)


def list_datasets():
    """列出所有可用数据集"""
    print("="*80)
    print("可用数据集列表")
    print("="*80)
    for name, cfg in DATASETS.items():
        print(f"\n[{name}]")
        print(f"    路径: {cfg['path']}")
        print(f"    平均长度: {cfg['avg_length']} chars")
        print(f"    描述: {cfg['description']}")
    print("\n" + "="*80)


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "services":
            list_services()
        elif sys.argv[1] == "datasets":
            list_datasets()
        else:
            print("用法: python3 benchmark_configs.py [services|datasets]")
    else:
        list_services()
        print()
        list_datasets()
