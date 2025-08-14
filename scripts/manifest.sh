#!/bin/bash
set -e

ECR_URL=""
IMG_NAME=""
TAG=""

usage() {
    echo "Usage: $0 -c <container_registry> -n <image_name> -t <tag>"
    exit 1
}

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

# Define image names for each architecture
IMAGE_AMD64="${ECR_URL}/${IMG_NAME}:amd64-${TAG}"
IMAGE_ARM64="${ECR_URL}/${IMG_NAME}:arm64-${TAG}"

# Create and push manifest with dual tags ("latest" and the version tag)
# The latest tag
echo "Creating multi-arch manifest for tag 'latest'..."
docker manifest rm ${ECR_URL}/${IMG_NAME}:latest || true
docker manifest create ${ECR_URL}/${IMG_NAME}:latest ${IMAGE_AMD64} ${IMAGE_ARM64}

echo "Annotating AMD64 image as default in the 'latest' manifest..."
docker manifest annotate ${ECR_URL}/${IMG_NAME}:latest ${IMAGE_AMD64} --os linux --arch amd64

echo "Pushing manifest for tag 'latest'..."
docker manifest push ${ECR_URL}/${IMG_NAME}:latest

# The version tag
echo "Creating multi-arch manifest for version tag '${TAG}'..."
docker manifest rm ${ECR_URL}/${IMG_NAME}:${TAG} || true
docker manifest create ${ECR_URL}/${IMG_NAME}:${TAG} ${IMAGE_AMD64} ${IMAGE_ARM64}

echo "Annotating AMD64 image as default in the '${TAG}' manifest..."
docker manifest annotate ${ECR_URL}/${IMG_NAME}:${TAG} ${IMAGE_AMD64} --os linux --arch amd64

echo "Pushing manifest for version tag '${TAG}'..."
docker manifest push ${ECR_URL}/${IMG_NAME}:${TAG}
