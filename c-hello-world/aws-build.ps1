# enter the IP address of an AWS A1 instance 
# Make sure to change the tag name of the image to your hub account

docker buildx create --use --platform linux/arm/v7,linux/arm64 --name aws-builder  ubuntu@100.26.131.243
docker buildx use aws-builder
docker buildx build --platform linux/arm64,linux/arm/v7 -t jasonrandrews/c-hello-world-a1 --push .
