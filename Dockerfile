# ComfyUI with Wan 2.1/2.2 I2V Models - Downloads at startup
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_DIR=/app/ComfyUI

RUN apt-get update && apt-get install -y \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/comfyanonymous/ComfyUI.git $COMFYUI_DIR
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager $COMFYUI_DIR/custom_nodes/comfyui-manager

# Install Python dependencies
RUN pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128 && \
    pip install -r $COMFYUI_DIR/requirements.txt && \
    pip install numpy==1.26.4 && \
    pip install hf_transfer

# Copy startup script and make it executable
COPY --chmod=755 startup.sh /app/startup.sh

WORKDIR $COMFYUI_DIR
EXPOSE 8888
ENTRYPOINT ["/app/startup.sh"]
