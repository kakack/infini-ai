#!/usr/bin/env python3
"""
BGE-M3 标准化压测脚本

用法:
  # 测试单个服务
  python3 run_benchmark.py --service Service3 --dataset 1k,4k,8k
  
  # 测试所有服务
  python3 run_benchmark.py --all-services --dataset 1k,4k,8k
  
  # 自定义 URL 测试
  python3 run_benchmark.py --url http://host:port/v1/embeddings --model bge-m3 --dataset 1k
"""

import argparse
import json
import sys
import os
from datetime import datetime

# 导入配置
from benchmark_configs import SERVICES, DATASETS, BENCHMARK_CONFIG


def run_single_test(url: str, model: str, dataset: str, concurrency: int, requests: int, output: str):
    """运行单个压测"""
    dataset_path = DATASETS[dataset]["path"]
    
    # 获取项目根目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    
    # 确定 benchmark_toolkit 路径
    toolkit_dir = os.path.join(script_dir, "bge-m3", "benchmark_toolkit")
    
    cmd = (
        f"cd '{toolkit_dir}' && "
        f"source '{project_root}/.venv/bin/activate' && "
        f"python3 benchmark.py "
        f"--url '{url}' "
        f"--model '{model}' "
        f"--dataset '{project_root}/{dataset_path}' "
        f"--concurrency {concurrency} "
        f"--requests {requests} "
        f"--output '{output}'"
    )
    
    print(f"\n执行: {cmd}")
    ret = os.system(cmd)
    return ret == 0


def convert_result_format(input_file: str, dataset: str, concurrency: int) -> dict:
    """将 benchmark.py 输出格式转换为标准格式"""
    with open(input_file) as f:
        data = json.load(f)
    
    key = f"concurrency_{concurrency}"
    if key not in data:
        return None
    
    r = data[key]
    
    return {
        "dataset": dataset,
        "concurrency": concurrency,
        "requests": r["total"],
        "elapsed_sec": r["throughput"]["total_time_sec"],
        "success": r["success"],
        "fail": r["fail"],
        "total": r["total"],
        "e2e_time": {
            "P50": r["e2e_time_ms"]["P50"],
            "P90": r["e2e_time_ms"]["P90"],
            "P99": r["e2e_time_ms"]["P99"],
            "avg": r["e2e_time_ms"]["avg"],
            "min": r["e2e_time_ms"]["min"],
            "max": r["e2e_time_ms"]["max"]
        },
        "ttft": {
            "P50": r["ttft_ms"]["P50"],
            "P90": r["ttft_ms"]["P90"],
            "P99": r["ttft_ms"]["P99"],
            "avg": r["ttft_ms"]["avg"],
            "min": r["ttft_ms"]["min"],
            "max": r["ttft_ms"]["max"]
        },
        "throughput": r["throughput"]["req_per_sec"]
    }


def benchmark_service(service_name: str, datasets: list, output_dir: str = "results"):
    """对单个服务进行完整压测"""
    from benchmark_configs import get_service_by_name
    
    service = get_service_by_name(service_name)
    if not service:
        print(f"错误: 未找到服务 '{service_name}'")
        print("可用服务:", [s["name"] for s in SERVICES])
        return False
    
    print("="*80)
    print(f"开始压测: {service['name']}")
    print(f"URL: {service['url']}")
    print(f"Model: {service['model']}")
    print(f"数据集: {', '.join(datasets)}")
    print("="*80)
    
    os.makedirs(output_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    all_results = {}
    
    for dataset in datasets:
        if dataset not in DATASETS:
            print(f"警告: 未知数据集 '{dataset}'，跳过")
            continue
        
        print(f"\n{'='*60}")
        print(f"测试数据集: {dataset}")
        print(f"{'='*60}")
        
        for conc in BENCHMARK_CONFIG["concurrency_levels"]:
            test_key = f"{dataset}_c{conc}"
            raw_output = f"/tmp/{service['name'].replace(' ', '_').lower()}_{test_key}_{timestamp}.json"
            
            print(f"\n>>> 测试: {test_key} (并发={conc})")
            success = run_single_test(
                service["url"],
                service["model"],
                dataset,
                conc,
                BENCHMARK_CONFIG["requests_per_test"],
                raw_output
            )
            
            if success:
                result = convert_result_format(raw_output, dataset, conc)
                if result:
                    all_results[test_key] = result
                    print(f"    ✓ 完成: P50={result['e2e_time']['P50']:.2f}ms, "
                          f"Throughput={result['throughput']:.2f} req/s")
            else:
                print(f"    ✗ 失败")
    
    # 保存结果
    if all_results:
        result_file = f"{output_dir}/{service['name'].replace(' ', '_').lower()}_results_{timestamp}.json"
        with open(result_file, 'w') as f:
            json.dump(all_results, f, indent=2)
        print(f"\n{'='*80}")
        print(f"结果已保存: {result_file}")
        print(f"共完成 {len(all_results)} 组测试")
        print("="*80)
        return True
    
    return False


def main():
    parser = argparse.ArgumentParser(description='BGE-M3 标准化压测')
    
    # 服务选择
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--service', help='测试指定服务 (如: Service3)')
    group.add_argument('--all-services', action='store_true', help='测试所有配置的服务')
    group.add_argument('--url', help='自定义测试 URL')
    
    # 其他参数
    parser.add_argument('--model', default='bge-m3', help='模型名称 (默认: bge-m3)')
    parser.add_argument('--dataset', default='1k,4k,8k', 
                        help='测试数据集，逗号分隔 (默认: 1k,4k,8k)')
    parser.add_argument('--output-dir', default='results', help='输出目录')
    parser.add_argument('--list-services', action='store_true', help='列出可用服务')
    parser.add_argument('--list-datasets', action='store_true', help='列出可用数据集')
    
    args = parser.parse_args()
    
    # 列出模式
    if args.list_services:
        from benchmark_configs import list_services
        list_services()
        return
    
    if args.list_datasets:
        from benchmark_configs import list_datasets
        list_datasets()
        return
    
    # 解析数据集
    datasets = [d.strip() for d in args.dataset.split(',')]
    
    # 执行测试
    if args.all_services:
        print("="*80)
        print("批量测试所有服务")
        print("="*80)
        for service in SERVICES:
            benchmark_service(service["name"], datasets, args.output_dir)
            print("\n")
    
    elif args.service:
        benchmark_service(args.service, datasets, args.output_dir)
    
    elif args.url:
        # 自定义 URL 模式
        print("="*80)
        print("自定义 URL 测试")
        print(f"URL: {args.url}")
        print(f"Model: {args.model}")
        print("="*80)
        
        # 创建临时服务配置
        temp_service = {
            "name": "Custom",
            "url": args.url,
            "model": args.model
        }
        
        os.makedirs(args.output_dir, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        all_results = {}
        
        for dataset in datasets:
            if dataset not in DATASETS:
                continue
            
            for conc in BENCHMARK_CONFIG["concurrency_levels"]:
                test_key = f"{dataset}_c{conc}"
                raw_output = f"/tmp/custom_{test_key}_{timestamp}.json"
                
                print(f"\n>>> 测试: {test_key}")
                success = run_single_test(
                    args.url, args.model, dataset, conc,
                    BENCHMARK_CONFIG["requests_per_test"],
                    raw_output
                )
                
                if success:
                    result = convert_result_format(raw_output, dataset, conc)
                    if result:
                        all_results[test_key] = result
                        print(f"    ✓ P50={result['e2e_time']['P50']:.2f}ms, "
                              f"Tput={result['throughput']:.2f} req/s")
        
        if all_results:
            result_file = f"{args.output_dir}/custom_results_{timestamp}.json"
            with open(result_file, 'w') as f:
                json.dump(all_results, f, indent=2)
            print(f"\n结果已保存: {result_file}")


if __name__ == "__main__":
    main()
