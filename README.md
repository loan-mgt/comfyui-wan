# ComfyUI Wan 2.2 Docker

Docker image for Image-to-Video generation with ComfyUI and Wan 2.2 models.

## Quick Start

```bash
# Pull and run (basic usage)
docker pull ghcr.io/loan-mgt/comfyui-wan:latest
docker run -d --name comfyui-i2v --gpus all -p 8188:8888 ghcr.io/loan-mgt/comfyui-wan:latest
```

### With HuggingFace Token (Recommended for faster downloads)

For blazingly fast download speeds and access to gated models, provide your HuggingFace token:

```bash
# Using HuggingFace token for faster downloads
docker run -d --name comfyui-i2v --gpus all -p 8188:8888 \
  ghcr.io/loan-mgt/comfyui-wan:latest "your_hf_token_here"
```

**To get your HuggingFace token:**
1. Go to https://huggingface.co/settings/tokens
2. Create a new token with "Read" permissions
3. Copy the token and use it in the docker run command above

Access at: http://localhost:8188

## Features

- **Fast Downloads**: Uses HuggingFace CLI with hf_transfer for up to 10x faster model downloads
- **Automatic Model Management**: Downloads missing models on first startup
- **Token Authentication**: Support for HuggingFace tokens for gated models and faster speeds
- **GPU Optimized**: Ready for NVIDIA GPUs with CUDA support

## Requirements

- Docker with GPU support
- NVIDIA GPU with 16GB+ VRAM

## Models Included

This container automatically downloads the following models on first startup:

- **VAE**: `wan_2.1_vae.safetensors` - Video Auto Encoder
- **CLIP Vision**: `clip_vision_h.safetensors` - Image understanding
- **Text Encoder**: `umt5_xxl_fp8_e4m3fn_scaled.safetensors` - Text processing
- **Diffusion Models**:
  - `wan2.2_i2v_high_noise_14B_fp16.safetensors` - High noise variant
  - `wan2.2_i2v_low_noise_14B_fp16.safetensors` - Low noise variant

Total download size: ~28GB

## Performance Notes

- **Without HF Token**: Downloads use standard HTTP with retry logic
- **With HF Token**: Downloads use hf_transfer for up to 10x faster speeds
- Models are cached between container restarts
- First startup may take 15-30 minutes depending on internet speed

## Advanced Usage

### Custom Model Directory

Mount a local directory to persist models:

```bash
docker run -d --name comfyui-i2v --gpus all -p 8188:8888 \
  -v /path/to/models:/app/ComfyUI/models \
  ghcr.io/loan-mgt/comfyui-wan:latest "your_hf_token_here"
```

### Environment Variables

- `HF_HUB_ENABLE_HF_TRANSFER=1`: Automatically enabled for faster downloads
- `COMFYUI_DIR=/app/ComfyUI`: ComfyUI installation directory
