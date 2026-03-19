# infini-ai

在 [Infini-AI](https://cloud.infini-ai.com/) 平台上下发训练和推理任务的脚本记录。

## 目录结构

```
.
├── inference/    # 推理任务脚本
├── training/     # 训练任务脚本
└── logs/         # 运行日志（不纳入版本管理）
```

## 推理脚本

| 脚本 | 说明 |
|------|------|
| `glm5_2n_vllm.sh` | GLM5 2节点 vLLM 推理 |
| `qwen3_5_397b-1n_vllm.sh` | Qwen3.5-397B 单节点 vLLM 推理 |
| `qwen3_5_397b-2n_vllm.sh` | Qwen3.5-397B 2节点 vLLM 推理 |
| `qwen3_coder_480b-4n-vllm.sh` | Qwen3-Coder-480B 4节点 vLLM 推理 |
| `kimi_k2_5-2n_vllm.sh` | Kimi-K2.5 2节点 vLLM 推理 |

## 使用方式

```bash
# 提交推理任务
bash inference/<script_name>.sh
```

## License

MIT
