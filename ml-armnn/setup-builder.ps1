# Setup a builder to the build the Arm NN software stack on AWS A1

# Replace the IP address of the A1 instance to use

docker buildx create --use --platform linux/arm/v7,linux/arm64 --name aws-builder  ubuntu@3.95.61.127
docker buildx use aws-builder
docker buildx inspect --bootstrap
