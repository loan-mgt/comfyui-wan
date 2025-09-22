#!/bin/bash

# ComfyUI Wan 2.1/2.2 Startup Script with Custom Model Support
#
# Usage Examples:
# ./startup.sh
# ./startup.sh --model "stabilityai/stable-diffusion-xl-base-1.0 lora_weights.safetensors loras/my_lora.safetensors"
# ./startup.sh --model "user/repo model.safetensors loras/style_lora.safetensors" --model "another/repo weights.bin checkpoints/character_model.bin"
#
# Model Argument Format: "repo_id filename local_path"
# - repo_id: Hugging Face repository (e.g., "stabilityai/stable-diffusion-xl-base-1.0")
# - filename: File name in the repository (e.g., "lora_weights.safetensors")
# - local_path: Full path within models directory (e.g., "loras/my_custom_lora.safetensors" or "checkpoints/model.safetensors")

echo "============================================================================"
echo "ComfyUI Wan 2.1/2.2 Startup - Checking Models"
echo "============================================================================"

# Parse command line arguments for custom models (LoRAs, checkpoints, etc.)
# Usage: --model "repo_id filename local_path" --model "repo_id filename local_path" ...
CUSTOM_MODELS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            if [[ -n "$2" ]]; then
                CUSTOM_MODELS+=("$2")
                shift 2
            else
                echo "Error: --model requires a value in format 'repo_id filename local_path'"
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
    
    # If model_config is not provided, get it from MODELS array
    if [ -z "$model_config" ]; then
        model_config="${MODELS[$model_key]}"
    fi
    
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
        
        # Determine download directory based on the local_path
        local download_dir="$COMFYUI_DIR/models"
        local target_subdir=""
        
        # Extract the subdirectory from local_path (e.g., "loras" from "loras/file.safetensors")
        if [[ "$local_path" == */* ]]; then
            target_subdir="${local_path%/*}"
            download_dir="$COMFYUI_DIR/models/$target_subdir"
        fi
        
        # Use hf download with hf_transfer for faster downloads
        if hf download "$repo_id" "$filename" --local-dir "$download_dir"; then
            # Create a symbolic link from the expected location to the downloaded file
            local downloaded_file="$download_dir/$filename"
            if [ -f "$downloaded_file" ] && [ "$downloaded_file" != "$full_path" ]; then
                ln -s "$downloaded_file" "$full_path"
                echo "✓ Successfully downloaded and linked: $local_path"
            elif [ -f "$full_path" ]; then
                echo "✓ Successfully downloaded: $local_path"
            else
                echo "✗ Downloaded file not found at expected location"
            fi
        else
            echo "✗ Failed to download: $local_path"
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

# Download custom models if provided
if [ ${#CUSTOM_MODELS[@]} -gt 0 ]; then
    echo "============================================================================"
    echo "Processing Custom Models"
    echo "============================================================================"
    
    model_counter=1
    for model_config in "${CUSTOM_MODELS[@]}"; do
        echo "[$model_counter/${#CUSTOM_MODELS[@]}] Processing custom model"
        
        # Parse the model configuration 
        # The local_path should include the full path within models directory
        read -r repo_id filename local_path <<< "$model_config"
        
        # Debug: Print what we parsed
        echo "   Parsed - Repo: '$repo_id', File: '$filename', Local: '$local_path'"
        
        # Use the local_path as provided (user specifies full path)
        model_model_config="$repo_id $filename $local_path"
        
        # Use the reusable download function
        download_if_missing "custom_model_$model_counter" "$model_model_config"
        
        ((model_counter++))
    done
fi

echo "============================================================================"
echo "Model check complete! Starting ComfyUI..."
echo "============================================================================"

# Start ComfyUI
cd $COMFYUI_DIR
exec python main.py --listen 0.0.0.0 --port 8888