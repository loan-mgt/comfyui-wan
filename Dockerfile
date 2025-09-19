# ComfyUI with Wan 2.1/2.2 I2V Models Docker Image
FROM runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_DIR=/app/ComfyUI

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git $COMFYUI_DIR

# Clone ComfyUI Manager into custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager $COMFYUI_DIR/custom_nodes/comfyui-manager

# Install Python dependencies
RUN pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128 && \
    pip install -r $COMFYUI_DIR/requirements.txt && \
    pip install numpy==1.26.4

# Create model directories
RUN mkdir -p $COMFYUI_DIR/models/vae \
    && mkdir -p $COMFYUI_DIR/models/clip_vision \
    && mkdir -p $COMFYUI_DIR/models/text_encoders \
    && mkdir -p $COMFYUI_DIR/models/diffusion_models

# Download Wan 2.1/2.2 model files using ADD
# VAE model
ADD https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors \
    $COMFYUI_DIR/models/vae/wan_2.1_vae.safetensors

# CLIP Vision model
ADD https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors \
    $COMFYUI_DIR/models/clip_vision/clip_vision_h.safetensors

# Text encoder model
ADD https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
    $COMFYUI_DIR/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

# Diffusion models (Wan 2.2)
ADD https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors \
    $COMFYUI_DIR/models/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors

ADD https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors \
    $COMFYUI_DIR/models/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors

# Set proper permissions for downloaded model files
RUN chmod 644 $COMFYUI_DIR/models/*/*.safetensors

# Set working directory to ComfyUI
WORKDIR $COMFYUI_DIR

# Expose the default ComfyUI port
EXPOSE 8188

# Start ComfyUI server
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]