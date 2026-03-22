FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_DIR=/app/ComfyUI
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PIP_ROOT_USER_ACTION=ignore
ENV HF_HOME=/app/ComfyUI/models/.cache/huggingface/

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO- https://astral.sh/uv/install.sh | sh && \
    ln -s /root/.local/bin/uv /usr/local/bin/uv

WORKDIR /app

RUN git clone https://github.com/comfyanonymous/ComfyUI.git $COMFYUI_DIR && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager $COMFYUI_DIR/custom_nodes/comfyui-manager && \
    git clone https://github.com/loan-mgt/hf-lora-loader.git $COMFYUI_DIR/custom_nodes/hf-lora-loader && \
    git clone https://github.com/MadiatorLabs/ComfyUI-RunpodDirect.git $COMFYUI_DIR/custom_nodes/ComfyUI-RunpodDirect && \
    git clone https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler $COMFYUI_DIR/custom_nodes/ComfyUI-SeedVR2_VideoUpscaler

RUN uv pip install --system --break-system-packages \
        -r $COMFYUI_DIR/requirements.txt \
        -r $COMFYUI_DIR/custom_nodes/ComfyUI-SeedVR2_VideoUpscaler/requirements.txt \
        "numpy==1.26.4" \
        "huggingface_hub[cli]"

COPY --chmod=755 startup.sh /app/startup.sh
WORKDIR $COMFYUI_DIR
EXPOSE 8888
ENTRYPOINT ["/app/startup.sh"]
