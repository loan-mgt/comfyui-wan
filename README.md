# ComfyUI Video Docker

Docker image for ComfyUI video generation, supporting models such as LTX 2.3, Wan 2.2, and more. Built on RunPod PyTorch.

## Quick Start

```bash
# Pull and run
docker pull ghcr.io/loan-mgt/comfyui-wan:latest
docker run -d --name comfyui --gpus all -p 8188:8888 ghcr.io/loan-mgt/comfyui-wan:latest
```

Access at: http://localhost:8188

## Features

- **RunPod Base**: Built on `runpod/pytorch` with CUDA 12.8.1 and PyTorch 2.8.0
- **uv Package Manager**: System-level Python dependencies managed with `uv`
- **Fast HF Downloads**: `HF_XET_HIGH_PERFORMANCE=1` enabled for accelerated Hugging Face transfers
- **Custom LoRA Support**: Download custom LoRA models from Hugging Face at startup via `--model`
- **Private Model Support**: Pass a Hugging Face token at runtime via `--hf-token`
- **Bundled Custom Nodes**:
  - [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
  - [hf-lora-loader](https://github.com/loan-mgt/hf-lora-loader)
  - [ComfyUI-RunpodDirect](https://github.com/MadiatorLabs/ComfyUI-RunpodDirect)
  - [ComfyUI-SeedVR2_VideoUpscaler](https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler)

## Requirements

- Docker with GPU support
- NVIDIA GPU (16 GB+ VRAM recommended)

## Advanced Usage

### Persist Models

Mount a local directory so models survive container restarts:

```bash
docker run -d --name comfyui --gpus all -p 8188:8888 \
  -v /path/to/models:/app/ComfyUI/models \
  ghcr.io/loan-mgt/comfyui-wan:latest
```

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `COMFYUI_DIR` | `/app/ComfyUI` | ComfyUI installation directory |
| `HF_HOME` | `/app/ComfyUI/models/.cache/huggingface/` | Hugging Face cache location |
| `HF_XET_HIGH_PERFORMANCE` | `1` | Enables high-performance Xet-backed HF transfers |

### Python Environment

- Dependencies are installed system-wide using `uv pip install --system`
- ComfyUI is started with `python3 main.py --listen 0.0.0.0 --port 8888`

### Custom LoRA Models

Download LoRA models from Hugging Face at startup using `--model`. Files are saved to `models/loras/{filename}`.

```bash
# Single LoRA
docker run -d --name comfyui --gpus all -p 8188:8888 \
  ghcr.io/loan-mgt/comfyui-wan:latest \
  --model "user/repo lora_weights.safetensors"

# Multiple LoRAs
docker run -d --name comfyui --gpus all -p 8188:8888 \
  ghcr.io/loan-mgt/comfyui-wan:latest \
  --model "user/repo style_lora.safetensors" \
  --model "another/repo character_lora.safetensors"
```

`--model` format: `"repo_id filename"` (space-separated)

### Private Models (Hugging Face Token)

```bash
docker run -d --name comfyui --gpus all -p 8188:8888 \
  ghcr.io/loan-mgt/comfyui-wan:latest \
  --hf-token "hf_yourTokenHere" \
  --model "private-user/private-repo model.safetensors"
```
