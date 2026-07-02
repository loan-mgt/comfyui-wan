FROM runpod/pytorch:1.0.7-cu1300-torch291-ubuntu2404
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

RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git $COMFYUI_DIR && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager $COMFYUI_DIR/custom_nodes/comfyui-manager && \
    git clone --depth 1 https://github.com/loan-mgt/hf-lora-loader.git $COMFYUI_DIR/custom_nodes/hf-lora-loader && \
    git clone --depth 1 https://github.com/MadiatorLabs/ComfyUI-RunpodDirect.git $COMFYUI_DIR/custom_nodes/ComfyUI-RunpodDirect

RUN grep -vE '^(torch|torchvision|torchaudio)([=<> ]|$)' $COMFYUI_DIR/requirements.txt > $COMFYUI_DIR/requirements.filtered.txt

RUN uv pip install --system --break-system-packages \
    -r $COMFYUI_DIR/requirements.filtered.txt \
    "numpy==1.26.4" \
    "huggingface_hub[cli]" && \
    for d in $COMFYUI_DIR/custom_nodes/*/; do \
    if [ -f "$d/requirements.txt" ]; then \
    echo "Installing deps for $d" && \
    grep -vE '^(torch|torchvision|torchaudio)([=<> ]|$)' "$d/requirements.txt" > "$d/requirements.filtered.txt" && \
    uv pip install --system --break-system-packages -r "$d/requirements.filtered.txt"; \
    fi \
    done

COPY --chmod=755 startup.sh /app/startup.sh
WORKDIR $COMFYUI_DIR
EXPOSE 8888
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD wget -q --spider http://localhost:8888/system_stats || exit 1
ENTRYPOINT ["/app/startup.sh"]