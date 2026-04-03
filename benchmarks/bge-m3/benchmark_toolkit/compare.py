#!/usr/bin/env python3
"""
双服务对比分析工具

用法:
  python3 compare.py service1_results.json service2_results.json
"""

import argparse
import json

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('service1', help='First service result JSON')
    parser.add_argument('service2', help='Second service result JSON')
    parser.add_argument('--name1', default='Service 1')
    parser.add_argument('--name2', default='Service 2')
    args = parser.parse_args()
    
    with open(args.service1) as f:
        s1 = json.load(f)
    with open(args.service2) as f:
        s2 = json.load(f)
    
    print("="*80)
    print("Service Comparison Report")
    print("="*80)
    print(f"\n{args.name1} vs {args.name2}")
    print()
    
    for test in s1.keys():
        if test not in s2:
            continue
        r1, r2 = s1[test], s2[test]
        print(f"【{test}】")
        print(f"  P50 E2E: {r1['e2e_time_ms']['P50']:.2f} ms vs {r2['e2e_time_ms']['P50']:.2f} ms")
        print(f"  Throughput: {r1['throughput']['req_per_sec']:.2f} vs {r2['throughput']['req_per_sec']:.2f} req/s")
        print()

if __name__ == "__main__":
    main()
