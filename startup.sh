#!/bin/bash

echo "============================================================================"
echo "ComfyUI Wan 2.1/2.2 Startup - Checking Models"
echo "============================================================================"

# Handle HuggingFace authentication if token is provided
if [ "$1" ]; then
    echo "🔑 Authenticating with HuggingFace..."
    echo "$1" | huggingface-cli login --token
    if [ $? -eq 0 ]; then
        echo "✓ Successfully authenticated with HuggingFace"
    else
        echo "⚠️ Warning: HuggingFace authentication failed, proceeding without auth"
    fi
    echo
fi

# Enable hf_transfer for faster downloads
export HF_HUB_ENABLE_HF_TRANSFER=1

# Model configurations: [repo_id, filename, local_path]
declare -A MODELS=(
    ["vae"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/vae/wan_2.1_vae.safetensors vae/wan_2.1_vae.safetensors"
    ["clip_vision"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/clip_vision/clip_vision_h.safetensors clip_vision/clip_vision_h.safetensors"
    ["text_encoder"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    ["diffusion_high"]="Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors"
    ["diffusion_low"]="Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors"
)

# Create model directories
mkdir -p $COMFYUI_DIR/models/vae
mkdir -p $COMFYUI_DIR/models/clip_vision
mkdir -p $COMFYUI_DIR/models/text_encoders
mkdir -p $COMFYUI_DIR/models/diffusion_models

# Function to download a model if it doesn't exist
download_if_missing() {
    local model_key="$1"
    local model_config="${MODELS[$model_key]}"
    
    # Parse the model configuration
    read -r repo_id filename local_path <<< "$model_config"
    local full_path="$COMFYUI_DIR/models/$local_path"
    
    if [ -f "$full_path" ]; then
        echo "✓ Model already exists: $local_path"
    else
        echo "⏬ Downloading missing model: $local_path"
        echo "   Repository: $repo_id"
        echo "   File: $filename"
        
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$full_path")"
        
        # Use huggingface-cli with hf_transfer for faster downloads
        if huggingface-cli download "$repo_id" "$filename" --local-dir "$COMFYUI_DIR/models" --local-dir-use-symlinks False; then
            echo "✓ Successfully downloaded: $local_path"
        else
            echo "✗ Failed to download: $local_path"
            echo "   You can manually download it later and restart the container"
            echo "   Or provide a valid HuggingFace token if the model requires authentication"
        fi
    fi
    echo
}

# Check and download each model
counter=1
total=${#MODELS[@]}

for model_key in "${!MODELS[@]}"; do
    echo "[$counter/$total] Checking: $model_key"
    download_if_missing "$model_key"
    ((counter++))
done

echo "============================================================================"
echo "Model check complete! Starting ComfyUI..."
echo "============================================================================"

# Start ComfyUI
cd $COMFYUI_DIR
exec python main.py --listen 0.0.0.0 --port 8888