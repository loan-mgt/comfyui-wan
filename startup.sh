#!/bin/bash

# ComfyUI Wan 2.1/2.2 Startup Script with Custom Model Support
#
# Usage Examples:
# ./startup.sh
# ./startup.sh --model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
# ./startup.sh --model "user/repo custom_lora.safetensors" --model "another/repo another_lora.safetensors"
#
# Model Argument Format for --model: "repo_id filename"
# - repo_id: Hugging Face repository (e.g., "stabilityai/stable-diffusion-xl-base-1.0")
# - filename: File name in the repository (e.g., "lora_weights.safetensors")
#
# NOTE: When using --model the script will place the downloaded file under
#       models/loras/{filename} (local_path is automatically determined).

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
                # Expecting: "repo_id filename"
                CUSTOM_MODELS+=("$2")
                shift 2
            else
                echo "Error: --model requires a value in format 'repo_id filename'"
                exit 1
            fi
            ;;
        *)
            # Unknown option, skip it
            shift
            ;;
    esac
done

# huggingface_hub uses hf_xet automatically when available

# Resolve Hugging Face download command from virtualenv only
HF_CMD=""
HF_PYTHON="$COMFYUI_DIR/.venv/bin/python"
if [ -x "$COMFYUI_DIR/.venv/bin/hf" ]; then
    HF_CMD="$COMFYUI_DIR/.venv/bin/hf"
elif [ -x "$HF_PYTHON" ]; then
    HF_CMD="$HF_PYTHON"
fi

# Model configurations: [repo_id, filename, local_path]
declare -A MODELS=(
    ["vae"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/vae/wan_2.1_vae.safetensors vae/wan_2.1_vae.safetensors"
    ["clip_vision"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/clip_vision/clip_vision_h.safetensors clip_vision/clip_vision_h.safetensors"
    ["text_encoder"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    ["diffusion_high_fp8"]="Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
    ["diffusion_low_fp8"]="Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
    ["lora_high_4steps"]="Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
    ["lora_low_4steps"]="Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
    ["qwen_image_vae"]="Comfy-Org/Qwen-Image_ComfyUI split_files/vae/qwen_image_vae.safetensors vae/qwen_image_vae.safetensors"
    ["text_encoder_2.5_vl_7b_fp8_scaled"]="Comfy-Org/Qwen-Image_ComfyUI split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
    ["diffusion_image_edit_2509_fp8_e4m3fn"]="Comfy-Org/Qwen-Image-Edit_ComfyUI split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors"
    ["qwen_image_edit_lightning_4steps_v1.0_bf16"]="lightx2v/Qwen-Image-Lightning Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors loras/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors"
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
        
        if [ -z "$HF_CMD" ]; then
            echo "✗ Hugging Face download command not found. Install huggingface_hub[cli] and rebuild the image."
            echo "   You can manually download it later and restart the container"
        # Use huggingface_hub download command from venv
        elif [ "$HF_CMD" = "$HF_PYTHON" ] && "$HF_CMD" -m huggingface_hub download "$repo_id" "$filename" --local-dir "$download_dir"; then
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
        elif "$HF_CMD" download "$repo_id" "$filename" --local-dir "$download_dir"; then
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
    # Expecting: "repo_id filename" (local_path will be set to loras/{filename})
    read -r repo_id filename <<< "$model_config"

    # Determine local_path automatically for custom models
    local_path="loras/$filename"

    # Debug: Print what we parsed
    echo "   Parsed - Repo: '$repo_id', File: '$filename', Local: '$local_path'"

    # Build a full model config string and use the reusable download function
    model_model_config="$repo_id $filename $local_path"
    download_if_missing "custom_model_$model_counter" "$model_model_config"
        
        ((model_counter++))
    done
fi

echo "============================================================================"
echo "Model check complete! Starting ComfyUI..."
echo "============================================================================"

# Start ComfyUI
cd $COMFYUI_DIR
PYTHON_EXEC="$COMFYUI_DIR/.venv/bin/python"
if [ ! -x "$PYTHON_EXEC" ]; then
    echo "⚠ Virtual environment python not found at $PYTHON_EXEC, falling back to system python"
    PYTHON_EXEC="python"
fi
exec "$PYTHON_EXEC" main.py --listen 0.0.0.0 --port 8888