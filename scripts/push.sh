#!/bin/bash
set -e

ECR_URL=""
IMG_NAME=""
TAG=""
ARCH=""

usage() {
    echo "Usage: $0 -c <container_registry> -n <image_name> -t <tag> [--arm64]"
    exit 1
}

# Optional flag to explicitly set ARM architecture
ARM_OVERRIDE=false

# Parse command-line parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--container-registry)
            ECR_URL="$2"
            shift 2
            ;;
        -n|--image-name)
            IMG_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        --arm64)
            ARM_OVERRIDE=true
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            usage
            ;;
    esac
done

if [[ -z "$ECR_URL" || -z "$IMG_NAME" || -z "$TAG" ]]; then
    echo "Error: container registry, image name, and tag are required."
    usage
fi

if $ARM_OVERRIDE; then
    ARCH="arm64"
else
    # Auto-detect CPU architecture
    MACHINE_ARCH=$(uname -m)
    echo "Detected machine architecture: ${MACHINE_ARCH}"
    case "${MACHINE_ARCH}" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            echo "Unsupported architecture: ${MACHINE_ARCH}"
            exit 1
            ;;
    esac
fi

TARGET_IMAGE="${ECR_URL}/${IMG_NAME}:${ARCH}-${TAG}"

echo "Tagging image as ${TARGET_IMAGE}..."
docker tag ${ECR_URL}/${IMG_NAME}:latest ${TARGET_IMAGE}
# docker rmi -f ${ECR_URL}/${IMG_NAME}:latest 

echo "Pushing ${TARGET_IMAGE}..."
docker push ${TARGET_IMAGE}
