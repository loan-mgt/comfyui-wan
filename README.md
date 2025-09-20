# ComfyUI Wan 2.2 Docker

Docker image for Image-to-Video generation with ComfyUI and Wan 2.2 models.

## Quick Start

```bash
# Pull and run
docker pull ghcr.io/loan-mgt/comfyui-wan:latest
docker run -d --name comfyui-i2v --gpus all -p 8188:8888 ghcr.io/loan-mgt/comfyui-wan:latest
```

Access at: http://localhost:8188

## Requirements

- Docker with GPU support
- NVIDIA GPU with 16GB+ VRAM
