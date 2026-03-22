#!/bin/bash
set -euo pipefail

# ComfyUI Wan 2.1/2.2 Startup Script with Custom Model Support
#
# Usage Examples:
# ./startup.sh
# ./startup.sh --hf-token "hf_xxx"
# ./startup.sh --model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
# ./startup.sh --hf-token "hf_xxx" --model "user/repo custom_lora.safetensors"
# ./startup.sh --model "user/repo custom_lora.safetensors" --model "another/repo another_lora.safetensors"
#
# Model Argument Format for --model: "repo_id filename"
# NOTE: custom models are placed under models/loras/{filename}
# Auth Argument Format: --hf-token "hf_xxx"

HF="hf"

PYTHON_BIN="python3"

export HF_XET_HIGH_PERFORMANCE=1

echo "============================================================================"
echo "ComfyUI Wan 2.1/2.2 Startup - Checking Models"
echo "============================================================================"

# Parse --model "repo_id filename" arguments
CUSTOM_MODELS=()
HF_TOKEN_ARG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            [[ -n "$2" ]] || { echo "Error: --model requires a value in format 'repo_id filename'"; exit 1; }
            CUSTOM_MODELS+=("$2")
            shift 2
            ;;
        --hf-token)
            [[ $# -ge 2 && -n "$2" ]] || { echo "Error: --hf-token requires a token value"; exit 1; }
            HF_TOKEN_ARG="$2"
            shift 2
            ;;
        --hf-token=*)
            HF_TOKEN_ARG="${1#*=}"
            [[ -n "$HF_TOKEN_ARG" ]] || { echo "Error: --hf-token requires a token value"; exit 1; }
            shift
            ;;
        *) shift ;;
    esac
done

if [[ -n "$HF_TOKEN_ARG" ]]; then
    export HF_TOKEN="$HF_TOKEN_ARG"
    export HUGGINGFACE_HUB_TOKEN="$HF_TOKEN_ARG"
fi

# Model configurations: "repo_id hf_filename local_path_under_models/"
declare -A MODELS=()

mkdir -p "$COMFYUI_DIR/models/"{vae,clip_vision,text_encoders,diffusion_models,upscale_models,loras}

# Download a model and symlink it to its flat local_path so ComfyUI sees both paths.
# hf_xet may crash during Python teardown (Fatal Python error: _PyImport_Init) even
# after a successful download, so we ignore the exit code and check file existence directly.
download_if_missing() {
    local repo_id="$1" filename="$2" local_path="$3"
    local full_path="$COMFYUI_DIR/models/$local_path"
    local download_dir="$COMFYUI_DIR/models/${local_path%/*}"

    if [[ -f "$full_path" ]]; then
        echo "✓ Already exists: $local_path"
        return
    fi

    echo "⏬ Downloading: $local_path  ($repo_id / $filename)"
    mkdir -p "$download_dir"

    "$HF" download "$repo_id" "$filename" --local-dir "$download_dir" || true

    local downloaded_file="$download_dir/$filename"
    if [[ -f "$downloaded_file" && "$downloaded_file" != "$full_path" ]]; then
        ln -sf "$downloaded_file" "$full_path"
        echo "✓ Downloaded and linked: $local_path"
    elif [[ -f "$full_path" ]]; then
        echo "✓ Downloaded: $local_path"
    else
        echo "✗ Failed to download: $local_path"
    fi
    echo
}

# Built-in models
counter=1
total=${#MODELS[@]}
for key in "${!MODELS[@]}"; do
    echo "[$((counter++))/$total] $key"
    read -r repo_id filename local_path <<< "${MODELS[$key]}"
    download_if_missing "$repo_id" "$filename" "$local_path"
done

# Custom models passed via --model
if [[ ${#CUSTOM_MODELS[@]} -gt 0 ]]; then
    echo "============================================================================"
    echo "Processing Custom Models"
    echo "============================================================================"
    counter=1
    for model_config in "${CUSTOM_MODELS[@]}"; do
        read -r repo_id filename <<< "$model_config"
        echo "[$((counter++))/${#CUSTOM_MODELS[@]}] $repo_id / $filename"
        download_if_missing "$repo_id" "$filename" "loras/$filename"
    done
fi

echo "============================================================================"
echo "Model check complete! Starting ComfyUI..."
echo "============================================================================"

cd "$COMFYUI_DIR"
exec "$PYTHON_BIN" main.py --listen 0.0.0.0 --port 8888