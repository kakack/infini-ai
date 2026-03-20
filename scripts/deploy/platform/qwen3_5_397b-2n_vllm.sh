#!/bin/bash

###################################
# 平台任务启动脚本：VLLM 推理
# 适用模型：Qwen3.5-397B-A17B-W8A8
# 配置：TP8 DP2 (共 2 节点，每节点 8 卡，合计 16 卡；每节点一个 DP 副本)
# 启动方式：vLLM 原生多节点 (mp backend + --nnodes + --node-rank)
# 上下文窗口：256k (262144 tokens)
###################################

# 1. 基础依赖安装 (如果镜像已包含可注释)
sudo apt install -y dnsutils net-tools netcat-openbsd

# 2. 核心环境变量设置
ulimit -n 65536

# MACA 算子与内存优化
export MACA_GRAPH_LAUNCH_MODE=5
export MACA_SMALL_PAGESIZE_ENABLE=1
export MACA_DIRECT_DISPATCH=1
export MACA_VLLM_ENABLE_MCTIASS_FUSED_MOE=1
export MACA_VLLM_ENABLE_MCTIASS_PYTHON_API=1
export TRITON_ENABLE_MACA_OPT_MMA_PREFETCH=1
export TRITON_ENABLE_MACA_COMPILER_INT8_OPT=True
export TRITON_ENABLE_ELEMENTWISE_PK_FMA_OPT=True

# 网络配置
export GLOO_SOCKET_IFNAME=eth0
export MCCL_SOCKET_IFNAME=eth0
export MCCL_IB_HCA=mlx5_0,mlx5_1

# 3. 离线模式设置
export HF_DATASETS_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export VLLM_NO_USAGE_STATS=1

# 4. 模型路径
export MODEL_PATH="/mnt/public/model/huggingface/metax-tech/Qwen3.5-397B-A17B-W8A8"

# block-size 控制 KV cache 分页大小，256k 长上下文场景建议 64 或 128
# 可选值：16（默认）/ 32 / 64 / 128 / 256
# 启动时覆盖：BLOCK_SIZE=128 bash qwen3_5_397b-2n_vllm.sh
BLOCK_SIZE=${BLOCK_SIZE:-64}

# 5. 自动解析平台注入的环境变量
MASTER_ADDR=${MASTER_ADDR:-"localhost"}
NODE_RANK=${RANK:-"0"}
NNODES=${WORLD_SIZE:-"2"}

set -o pipefail

# 6. 获取主节点 IP (平台注入的 MASTER_ADDR 可能是 hostname，需解析为 IP)
HEAD_NODE_ADDRESS=$(dig $MASTER_ADDR | grep -A 1 "ANSWER SECTION" | grep "$MASTER_ADDR" | awk '{print $5}')
if [ -z "$HEAD_NODE_ADDRESS" ]; then
    HEAD_NODE_ADDRESS=$MASTER_ADDR
fi

echo "--- VLLM Multi-Node Info ---"
echo "Master Node IP   : $HEAD_NODE_ADDRESS"
echo "Current Node Rank: $NODE_RANK"
echo "Total Nodes      : $NNODES"
echo "Model Path       : $MODEL_PATH"
echo "----------------------------"

###################################
# 7. 启动 vLLM Server
#    主节点 (rank=0)：监听 8089 端口对外提供服务
#    从节点 (rank≠0)：--headless 模式，仅参与计算
###################################

if [ "$NODE_RANK" -eq 0 ]; then
    echo "#### Main Node (rank=0): starting vLLM with --port 8089"
    vllm serve $MODEL_PATH \
        --served-model-name Qwen3.5-397B \
        --trust-remote-code \
        -tp 8 -dp 2 \
        --distributed-executor-backend mp \
        --master-addr ${HEAD_NODE_ADDRESS} \
        --nnodes ${NNODES} \
        --node-rank ${NODE_RANK} \
        --host 0.0.0.0 \
        --port 8089 \
        --block-size ${BLOCK_SIZE} \
        --max-model-len 262144 \
        --max-num-seqs 32 \
        --max_num_batched_tokens 32768 \
        --gpu-memory-utilization 0.90 \
        --no-async-scheduling \
        --no-enable-prefix-caching \
        --enable-auto-tool-choice \
        --tool-call-parser qwen3_coder \
        --default-chat-template-kwargs '{"enable_thinking": false}' \
        --mm-encoder-tp-mode data \
        --mm-processor-cache-type shm \
        --limit-mm-per-prompt '{"image": 5, "video": 1}' \
        --skip-mm-profiling
else
    echo "#### Worker Node (rank=$NODE_RANK): starting vLLM with --headless"
    vllm serve $MODEL_PATH \
        --served-model-name Qwen3.5-397B \
        --trust-remote-code \
        -tp 8 -dp 2 \
        --distributed-executor-backend mp \
        --master-addr ${HEAD_NODE_ADDRESS} \
        --nnodes ${NNODES} \
        --node-rank ${NODE_RANK} \
        --block-size ${BLOCK_SIZE} \
        --max-model-len 262144 \
        --max-num-seqs 32 \
        --max_num_batched_tokens 32768 \
        --gpu-memory-utilization 0.90 \
        --no-async-scheduling \
        --no-enable-prefix-caching \
        --enable-auto-tool-choice \
        --tool-call-parser qwen3_coder \
        --default-chat-template-kwargs '{"enable_thinking": false}' \
        --mm-encoder-tp-mode data \
        --mm-processor-cache-type shm \
        --limit-mm-per-prompt '{"image": 5, "video": 1}' \
        --skip-mm-profiling \
        --headless
fi
