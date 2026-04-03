#!/usr/bin/env python3
"""
bge-m3 / Embedding Model Benchmark Tool
支持多并发、多数据集、完整统计指标

使用方法:
  python3 benchmark.py --url http://host:port/v1/embeddings --model bge-m3 --dataset /path/to/queries.jsonl --concurrency 1,8,16,64 --requests 2000
"""

import argparse
import json
import time
import statistics
import concurrent.futures
import sys
from datetime import datetime
from typing import List, Dict, Any
import threading

class BenchmarkResult:
    def __init__(self):
        self.e2e_times = []  # 端到端时间 (ms)
        self.ttfts = []      # 首token时间 (ms)
        self.success_count = 0
        self.fail_count = 0
        self.errors = []
    
    def add(self, e2e_time: float, ttft: float, success: bool, error: str = None):
        if success:
            self.e2e_times.append(e2e_time)
            self.ttfts.append(ttft)
            self.success_count += 1
        else:
            self.fail_count += 1
            if error:
                self.errors.append(error)
    
    def percentile(self, data: List[float], p: float) -> float:
        if not data:
            return 0
        sorted_data = sorted(data)
        k = (len(sorted_data) - 1) * p / 100
        f = int(k)
        c = f + 1 if f + 1 < len(sorted_data) else f
        if c == f:
            return sorted_data[f]
        return sorted_data[f] + (k - f) * (sorted_data[c] - sorted_data[f])
    
    def report(self) -> Dict[str, Any]:
        if not self.e2e_times:
            return {"error": "No successful requests"}
        
        total_time = sum(self.e2e_times) / 1000  # 转换为秒
        return {
            "success": self.success_count,
            "fail": self.fail_count,
            "total": self.success_count + self.fail_count,
            "success_rate": f"{self.success_count / (self.success_count + self.fail_count) * 100:.2f}%",
            "e2e_time_ms": {
                "P50": round(self.percentile(self.e2e_times, 50), 2),
                "P90": round(self.percentile(self.e2e_times, 90), 2),
                "P99": round(self.percentile(self.e2e_times, 99), 2),
                "avg": round(statistics.mean(self.e2e_times), 2),
                "min": round(min(self.e2e_times), 2),
                "max": round(max(self.e2e_times), 2),
            },
            "ttft_ms": {
                "P50": round(self.percentile(self.ttfts, 50), 2),
                "P90": round(self.percentile(self.ttfts, 90), 2),
                "P99": round(self.percentile(self.ttfts, 99), 2),
                "avg": round(statistics.mean(self.ttfts), 2),
                "min": round(min(self.ttfts), 2),
                "max": round(max(self.ttfts), 2),
            },
            "throughput": {
                "req_per_sec": round(self.success_count / total_time, 2) if total_time > 0 else 0,
                "total_time_sec": round(total_time, 2),
            }
        }

def send_request(api_url: str, model: str, query: str, timeout: int = 60) -> tuple:
    """发送单个 embedding 请求"""
    import requests
    
    headers = {
        "Content-Type": "application/json",
        "accept": "application/json"
    }
    payload = {
        "input": [query],
        "model": model,
        "input_type": "query"
    }
    
    start_time = time.time()
    ttft = None
    try:
        resp = requests.post(api_url, headers=headers, json=payload, timeout=timeout)
        ttft = time.time() - start_time
        
        if resp.status_code == 200:
            data = resp.json()
            e2e_time = time.time() - start_time
            if "data" in data and len(data["data"]) > 0:
                return (e2e_time * 1000, ttft * 1000, True, None)
            return (e2e_time * 1000, ttft * 1000, False, "No embedding in response")
        else:
            e2e_time = time.time() - start_time
            return (e2e_time * 1000, (ttft or 0) * 1000, False, f"HTTP {resp.status_code}")
    except Exception as e:
        e2e_time = time.time() - start_time
        return (e2e_time * 1000, (ttft or 0) * 1000, False, str(e)[:100])

def run_benchmark(api_url: str, model: str, queries: List[str], 
                  concurrency: int, max_requests: int, 
                  timeout: int = 60, progress_interval: int = 200) -> BenchmarkResult:
    """运行并发压测"""
    result = BenchmarkResult()
    completed = 0
    lock = threading.Lock()
    start_time = time.time()
    
    def worker(query: str):
        nonlocal completed
        e2e, ttft, success, error = send_request(api_url, model, query, timeout)
        with lock:
            result.add(e2e, ttft, success, error)
            completed += 1
            if completed % progress_interval == 0:
                elapsed = time.time() - start_time
                qps = completed / elapsed if elapsed > 0 else 0
                print(f"    Progress: {completed}/{max_requests} ({qps:.1f} req/s)", flush=True)
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [executor.submit(worker, q) for q in queries[:max_requests]]
        concurrent.futures.wait(futures)
    
    return result

def load_queries(dataset_path: str, max_requests: int) -> List[str]:
    """加载测试数据"""
    queries = []
    with open(dataset_path, 'r') as f:
        for i, line in enumerate(f):
            if i >= max_requests:
                break
            data = json.loads(line)
            queries.append(data.get('query', data.get('input', '')))
    return queries

def print_report(results: Dict[str, Any]):
    """打印格式化报告"""
    print("\n" + "="*80)
    print("BENCHMARK REPORT")
    print("="*80)
    
    for test_name, result in results.items():
        print(f"\n【{test_name}】")
        if "error" in result:
            print(f"  Error: {result['error']}")
            continue
        
        print(f"  Success: {result['success']}/{result['total']} ({result['success_rate']})")
        print(f"  Total Time: {result['throughput']['total_time_sec']}s")
        print(f"  Throughput: {result['throughput']['req_per_sec']} req/s")
        print(f"  E2E Time (ms): P50={result['e2e_time_ms']['P50']}, P90={result['e2e_time_ms']['P90']}, P99={result['e2e_time_ms']['P99']}")
        print(f"  TTFT (ms): P50={result['ttft_ms']['P50']}, P90={result['ttft_ms']['P90']}, P99={result['ttft_ms']['P99']}")
    
    print("\n" + "="*80)

def main():
    parser = argparse.ArgumentParser(description='Embedding Model Benchmark Tool')
    parser.add_argument('--url', required=True, help='API endpoint URL')
    parser.add_argument('--model', default='bge-m3', help='Model name')
    parser.add_argument('--dataset', required=True, help='Path to dataset JSONL file')
    parser.add_argument('--concurrency', default='1,8,16,64', help='Concurrency levels (comma-separated)')
    parser.add_argument('--requests', type=int, default=2000, help='Number of requests per test')
    parser.add_argument('--timeout', type=int, default=60, help='Request timeout in seconds')
    parser.add_argument('--output', default='benchmark_results.json', help='Output JSON file')
    
    args = parser.parse_args()
    
    concurrency_levels = [int(c.strip()) for c in args.concurrency.split(',')]
    
    print("="*80)
    print("Embedding Model Benchmark")
    print("="*80)
    print(f"API URL: {args.url}")
    print(f"Model: {args.model}")
    print(f"Dataset: {args.dataset}")
    print(f"Requests: {args.requests}")
    print(f"Concurrency: {concurrency_levels}")
    print("="*80)
    print()
    
    # 加载数据
    print(f"Loading dataset...")
    queries = load_queries(args.dataset, args.requests)
    avg_len = sum(len(q) for q in queries) / len(queries) if queries else 0
    print(f"  Loaded {len(queries)} queries, avg length: {avg_len:.0f} chars")
    print()
    
    # 运行测试
    all_results = {}
    for conc in concurrency_levels:
        test_name = f"concurrency_{conc}"
        print(f"Running test: {test_name}...")
        start = time.time()
        result = run_benchmark(args.url, args.model, queries, conc, args.requests, args.timeout)
        elapsed = time.time() - start
        report = result.report()
        all_results[test_name] = report
        print(f"  Completed in {elapsed:.1f}s")
    
    # 打印报告
    print_report(all_results)
    
    # 保存结果
    with open(args.output, 'w') as f:
        json.dump(all_results, f, indent=2)
    print(f"\nResults saved to: {args.output}")

if __name__ == "__main__":
    main()
