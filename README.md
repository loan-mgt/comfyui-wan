# ComfyUI Wan 2.2 Docker

Docker image for Image-to-Video generation with ComfyUI and Wan 2.2 models.

## Quick Start

```bash
# Pull and run
docker pull ghcr.io/loan-mgt/comfyui-wan:latest
docker run -d --name comfyui-i2v --gpus all -p 8188:8888 ghcr.io/loan-mgt/comfyui-wan:latest
```

Access at: http://localhost:8188

## Features

- **Fast Downloads**: Uses Hugging Face Hub with Xet-backed transfers (`hf_xet`) via `huggingface_hub`
- **Automatic Model Management**: Downloads missing models on first startup
- **uv Package Management**: Uses ComfyUI's default `uv` package manager with a project virtual environment
- **Custom LoRA Support**: Add custom LoRA models from Hugging Face at startup
- **GPU Optimized**: Ready for NVIDIA GPUs with CUDA support
- **Public Models**: All required models are publicly available, no authentication needed

## Requirements

- Docker with GPU support
- NVIDIA GPU with 16GB+ VRAM

Total download size: ~28GB

## Advanced Usage

### Custom Model Directory

Mount a local directory to persist models:

```bash
docker run -d --name comfyui-i2v --gpus all -p 8188:8888 \
  -v /path/to/models:/app/ComfyUI/models \
  ghcr.io/loan-mgt/comfyui-wan:latest
```

### Environment Variables

- `COMFYUI_DIR=/app/ComfyUI`: ComfyUI installation directory

Note: `hf_transfer` is deprecated upstream. This image uses current `huggingface_hub` behavior (including `hf_xet` when available).

### Python Environment

- Python dependencies are installed into `/app/ComfyUI/.venv` using `uv`
- ComfyUI is started with `/app/ComfyUI/.venv/bin/python`

### Custom LoRA Models

You can add custom LoRA models from Hugging Face by passing them as arguments to the startup script.

```bash
# Single custom LoRA (provide repo_id and filename)
docker run -d --name comfyui-i2v --gpus all -p 8188:8888 \
  ghcr.io/loan-mgt/comfyui-wan:latest \
  --model "stabilityai/stable-diffusion-xl-base-1.0 lora_weights.safetensors"

# Multiple custom LoRAs
docker run -d --name comfyui-i2v --gpus all -p 8188:8888 \
  ghcr.io/loan-mgt/comfyui-wan:latest \
  --model "user/repo style_lora.safetensors" \
  --model "another/repo character_lora.bin"
```

Model Argument Format for `--model`: `"repo_id filename"`
- `repo_id`: Hugging Face repository (e.g., "stabilityai/stable-diffusion-xl-base-1.0")
- `filename`: File name in the repository (e.g., "lora_weights.safetensors")

Note: When using `--model` the script will save the downloaded file under `/app/ComfyUI/models/loras/{filename}` by default.
