#!/bin/bash

export MACA_GRAPH_LAUNCH_MODE=5
export MACA_SMALL_PAGESIZE_ENABLE=1 
export MACA_DIRECT_DISPATCH=1 
export MACA_VLLM_ENABLE_MCTIASS_FUSED_MOE=1 
export MACA_VLLM_ENABLE_MCTIASS_PYTHON_API=1 

# block-size 控制 KV cache 分页大小，增大可支持更长的 max-model-len
# 可选值：16（默认）/ 32 / 64 / 128 / 256，建议先试 64
BLOCK_SIZE=${BLOCK_SIZE:-16}

cd /mnt/public/model/huggingface/metax-tech/

vllm serve Qwen3.5-397B-A17B-W8A8 \
    -tp 8 \
    --served-model-name Qwen3.5-397B \
    --trust-remote-code \
    --port 8089 \
    --block-size ${BLOCK_SIZE} \
    --max-model-len 32768 \
    --max_num_batched_tokens 8192 \
    --max-num-seqs 128 \
    --gpu-memory-utilization 0.89 \
    --no-async-scheduling \
    --enable-prefix-caching \
    --enable-auto-tool-choice \
    --tool-call-parser qwen3_coder \
    --default-chat-template-kwargs '{"enable_thinking": false}' \
    --mm-encoder-tp-mode data \
    --mm-processor-cache-type shm \
    --limit-mm-per-prompt '{"image": 5, "video": 1}' \
    --skip-mm-profiling