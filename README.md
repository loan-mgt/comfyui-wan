# ComfyUI Wan 2.2 Docker I2V

Ready to go Docker image for Image-to-Video (I2V) generation with ComfyUI, featuring the Wan 2.1/2.2 models.

## Features

- **ComfyUI** with latest version
- **ComfyUI Manager** for easy extension management
- **Pre-installed Wan 2.1/2.2 models**:
  - VAE: `wan_2.1_vae.safetensors`
  - CLIP Vision: `clip_vision_h.safetensors`
  - Text Encoder: `umt5_xxl_fp8_e4m3fn_scaled.safetensors`
  - Diffusion Models: `wan2.2_i2v_high_noise_14B_fp16.safetensors` and `wan2.2_i2v_low_noise_14B_fp16.safetensors`
- **CUDA 12.8 support** with PyTorch
- **Optimized for GPU inference**

## Quick Start

### Using GitHub Container Registry (Recommended)

Pull and run the pre-built image:

```bash
# Pull the latest image
docker pull ghcr.io/loan-mgt/comfyui-wan:latest

# Run with GPU support
docker run -d \
  --name comfyui-i2v \
  --gpus all \
  -p 8188:8080 \
  ghcr.io/loan-mgt/comfyui-wan:latest
```

### Building Locally

```bash
# Clone the repository
git clone https://github.com/loan-mgt/comfyui-wan.git
cd comfyui-wan

# Build the image
docker build -t comfyui-i2v .

# Run the container
docker run -d \
  --name comfyui-i2v \
  --gpus all \
  -p 8188:8080 \
  comfyui-i2v
```

## Access

Once the container is running, access ComfyUI at:
- **Web Interface**: http://localhost:8188

## Docker Compose (Optional)

Create a `docker-compose.yml` file:

```yaml
version: '3.8'
services:
  comfyui:
    image: ghcr.io/loan-mgt/comfyui-wan:latest
    container_name: comfyui-i2v
    ports:
      - "8188:8080"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    restart: unless-stopped
```

Run with: `docker-compose up -d`

## Requirements

- **Docker** with GPU support
- **NVIDIA Container Toolkit** (for GPU access)
- **NVIDIA GPU** with sufficient VRAM (recommended 16GB+ for full models)

## Model Information

This image includes the following pre-downloaded models:

| Model Type | File | Size | Purpose |
|------------|------|------|---------|
| VAE | wan_2.1_vae.safetensors | ~335MB | Video encoding/decoding |
| CLIP Vision | clip_vision_h.safetensors | ~2.5GB | Image understanding |
| Text Encoder | umt5_xxl_fp8_e4m3fn_scaled.safetensors | ~4.9GB | Text processing |
| Diffusion (High Noise) | wan2.2_i2v_high_noise_14B_fp16.safetensors | ~28GB | I2V generation |
| Diffusion (Low Noise) | wan2.2_i2v_low_noise_14B_fp16.safetensors | ~28GB | I2V generation |

## GitHub Actions

This repository includes automated Docker image building and publishing to GitHub Container Registry. Images are automatically built on:

- Push to `main`/`master` branch
- New tags (e.g., `v1.0.0`)
- Manual workflow dispatch

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Open an issue on GitHub
- Check ComfyUI documentation
- Review model documentation on Hugging Face
