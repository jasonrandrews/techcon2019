# The first command builds the full Arm NN SDK, a very large task and a 1 time procedure
# It's commented out here to save time, but refer to the Dockerfile and the
# build-armnn.sh script for details 

# Replace the Docker ID in the image tag and make sure to use docker login

# Each command builds a stage in the Dockerfile using the --target

# Base image derived from Ubuntu 18.04 used for all images
docker buildx build --platform linux/arm64,linux/arm/v7  --target base --push -t jasonrandrews/ubuntu-arm-base -f Dockerfile .

# Full Arm NN SDK build
#docker buildx build --platform linux/arm64,linux/arm/v7 --target sdk --push -t jasonrandrews/armnn-sdk -f Dockerfile .

# Builds the deverloper image used to create a software application with Arm NN
docker buildx build --platform linux/arm64,linux/arm/v7 --target dev --push -t jasonrandrews/armnn-dev -f Dockerfile .

# Build the release image used to run the application without the source code
docker buildx build --platform linux/arm64,linux/arm/v7 --target rel --push -t jasonrandrews/armnn-rel -f Dockerfile .
