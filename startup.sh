#!/bin/bash

# ComfyUI Wan 2.1/2.2 Startup Script with Custom LoRA Support
#
# Usage Examples:
# ./startup.sh
# ./startup.sh --lora "stabilityai/stable-diffusion-xl-base-1.0 lora_weights.safetensors my_lora.safetensors"
# ./startup.sh --lora "user/repo model.safetensors style_lora.safetensors" --lora "another/repo weights.bin character_lora.bin"
#
# LoRA Argument Format: "repo_id filename local_path"
# - repo_id: Hugging Face repository (e.g., "stabilityai/stable-diffusion-xl-base-1.0")
# - filename: File name in the repository (e.g., "lora_weights.safetensors")
# - local_path: Local filename to save as (e.g., "my_custom_lora.safetensors")

echo "============================================================================"
echo "ComfyUI Wan 2.1/2.2 Startup - Checking Models"
echo "============================================================================"

# Parse command line arguments for custom LoRA models
# Usage: --lora "repo_id filename local_path" --lora "repo_id filename local_path" ...
CUSTOM_LORAS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --lora)
            if [[ -n "$2" ]]; then
                CUSTOM_LORAS+=("$2")
                shift 2
            else
                echo "Error: --lora requires a value in format 'repo_id filename local_path'"
                exit 1
            fi
            ;;
        *)
            # Unknown option, skip it
            shift
            ;;
    esac
done

# Enable hf_transfer for faster downloads
export HF_HUB_ENABLE_HF_TRANSFER=1

# Model configurations: [repo_id, filename, local_path]
declare -A MODELS=(
    ["vae"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/vae/wan_2.1_vae.safetensors vae/wan_2.1_vae.safetensors"
    ["clip_vision"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/clip_vision/clip_vision_h.safetensors clip_vision/clip_vision_h.safetensors"
    ["text_encoder"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    ["diffusion_high"]="Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors"
    ["diffusion_low"]="Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors"
    ["upscale_nmkd"]="gemasai/4x_NMKD-Siax_200k 4x_NMKD-Siax_200k.pth upscale_models/4x_NMKD-Siax_200k.pth"
)

# Create model directories
mkdir -p $COMFYUI_DIR/models/vae
mkdir -p $COMFYUI_DIR/models/clip_vision
mkdir -p $COMFYUI_DIR/models/text_encoders
mkdir -p $COMFYUI_DIR/models/diffusion_models
mkdir -p $COMFYUI_DIR/models/upscale_models
mkdir -p $COMFYUI_DIR/models/loras

# Function to download a model if it doesn't exist
download_if_missing() {
    local model_key="$1"
    local model_config="$2"
    local model_type="${3:-model}"  # Default to "model", can be "LoRA" for custom downloads
    
    # If model_config is not provided, get it from MODELS array
    if [ -z "$model_config" ]; then
        model_config="${MODELS[$model_key]}"
    fi
    
    # Parse the model configuration
    read -r repo_id filename local_path <<< "$model_config"
    local full_path="$COMFYUI_DIR/models/$local_path"
    
    if [ -f "$full_path" ]; then
        echo "✓ $model_type already exists: $local_path"
    else
        echo "⏬ Downloading missing $model_type: $local_path"
        echo "   Repository: $repo_id"
        echo "   File: $filename"
        
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$full_path")"
        
        # Determine download directory based on model type
        local download_dir="$COMFYUI_DIR/models"
        if [[ "$model_type" == "LoRA" ]]; then
            download_dir="$COMFYUI_DIR/models/loras"
        fi
        
        # Use hf download with hf_transfer for faster downloads
        if hf download "$repo_id" "$filename" --local-dir "$download_dir"; then
            # Create a symbolic link from the expected location to the downloaded file
            local downloaded_file="$download_dir/$filename"
            if [ -f "$downloaded_file" ] && [ "$downloaded_file" != "$full_path" ]; then
                ln -s "$downloaded_file" "$full_path"
                echo "✓ Successfully downloaded and linked $model_type: $local_path"
            elif [ -f "$full_path" ]; then
                echo "✓ Successfully downloaded $model_type: $local_path"
            else
                echo "✗ Downloaded $model_type file not found at expected location"
            fi
        else
            echo "✗ Failed to download $model_type: $local_path"
            echo "   You can manually download it later and restart the container"
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

# Download custom LoRA models if provided
if [ ${#CUSTOM_LORAS[@]} -gt 0 ]; then
    echo "============================================================================"
    echo "Processing Custom LoRA Models"
    echo "============================================================================"
    
    lora_counter=1
    for lora_config in "${CUSTOM_LORAS[@]}"; do
        echo "[$lora_counter/${#CUSTOM_LORAS[@]}] Processing custom LoRA"
        
        # Parse the LoRA configuration 
        # The local_path should be the filename within the loras directory
        read -r repo_id filename local_path <<< "$lora_config"
        local lora_model_config="$repo_id $filename loras/$local_path"
        
        # Use the reusable download function
        download_if_missing "custom_lora_$lora_counter" "$lora_model_config" "LoRA"
        
        ((lora_counter++))
    done
fi

echo "============================================================================"
echo "Model check complete! Starting ComfyUI..."
echo "============================================================================"

# Start ComfyUI
cd $COMFYUI_DIR
exec python main.py --listen 0.0.0.0 --port 8888