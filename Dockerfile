# ComfyUI with Wan 2.1/2.2 I2V Models - Downloads at startup
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_DIR=/app/ComfyUI

RUN apt-get update && apt-get install -y \
    git \
    wget \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO- https://astral.sh/uv/install.sh | sh && \
    ln -s /root/.local/bin/uv /usr/local/bin/uv

WORKDIR /app

RUN git clone https://github.com/comfyanonymous/ComfyUI.git $COMFYUI_DIR
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager $COMFYUI_DIR/custom_nodes/comfyui-manager
RUN git clone https://github.com/loan-mgt/hf-lora-loader.git $COMFYUI_DIR/custom_nodes/hf-lora-loader
RUN git clone https://github.com/MadiatorLabs/ComfyUI-RunpodDirect.git $COMFYUI_DIR/custom_nodes/ComfyUI-RunpodDirect
RUN git clone https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler $COMFYUI_DIR/custom_nodes/ComfyUI-SeedVR2_VideoUpscaler

# Install Python dependencies
RUN uv venv $COMFYUI_DIR/.venv && \
    uv pip install --python $COMFYUI_DIR/.venv/bin/python --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128 && \
    uv pip install --python $COMFYUI_DIR/.venv/bin/python -r $COMFYUI_DIR/requirements.txt && \
    uv pip install --python $COMFYUI_DIR/.venv/bin/python numpy==1.26.4 && \
    uv pip install --python $COMFYUI_DIR/.venv/bin/python hf_transfer && \
    uv pip install --python $COMFYUI_DIR/.venv/bin/python -r $COMFYUI_DIR/custom_nodes/ComfyUI-SeedVR2_VideoUpscaler/requirements.txt

# Copy startup script and make it executable
COPY --chmod=755 startup.sh /app/startup.sh

WORKDIR $COMFYUI_DIR
EXPOSE 8888
ENTRYPOINT ["/app/startup.sh"]
