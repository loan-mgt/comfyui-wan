#!/bin/bash

echo "============================================================================"
echo "ComfyUI Wan 2.1/2.2 Startup - Checking Models"
echo "============================================================================"

# Model URLs and paths
declare -A MODELS=(
    ["vae/wan_2.1_vae.safetensors"]="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
    ["clip_vision/clip_vision_h.safetensors"]="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
    ["text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    ["diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors"]="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors"
    ["diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors"]="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors"
)

# Create model directories
mkdir -p $COMFYUI_DIR/models/vae
mkdir -p $COMFYUI_DIR/models/clip_vision
mkdir -p $COMFYUI_DIR/models/text_encoders
mkdir -p $COMFYUI_DIR/models/diffusion_models

# Function to download a model if it doesn't exist
download_if_missing() {
    local model_path="$1"
    local model_url="$2"
    local full_path="$COMFYUI_DIR/models/$model_path"
    
    if [ -f "$full_path" ]; then
        echo "✓ Model already exists: $model_path"
    else
        echo "⏬ Downloading missing model: $model_path"
        echo "   URL: $model_url"
        
        # Use wget with retry and progress bar
        if wget --progress=bar:force:noscroll --tries=3 --timeout=300 "$model_url" -O "$full_path"; then
            echo "✓ Successfully downloaded: $model_path"
        else
            echo "✗ Failed to download: $model_path"
            echo "   You can manually download it later and restart the container"
        fi
    fi
    echo
}

# Check and download each model
counter=1
total=${#MODELS[@]}

for model_path in "${!MODELS[@]}"; do
    echo "[$counter/$total] Checking: $model_path"
    download_if_missing "$model_path" "${MODELS[$model_path]}"
    ((counter++))
done

echo "============================================================================"
echo "Model check complete! Starting ComfyUI..."
echo "============================================================================"

# Start ComfyUI
cd $COMFYUI_DIR
exec python main.py --listen 0.0.0.0 --port 8888