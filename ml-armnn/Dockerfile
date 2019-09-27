#----------------------------------------------------------------------------
# Base image derived from Ubuntu 18.04 used as the starting point for all stages
# Install all needed tools and setup the user account
# The final release image could be optimized to be smaller if needed
#----------------------------------------------------------------------------

FROM ubuntu:18.04 as base

RUN echo "root:Arm2019" | chpasswd

RUN apt-get update -y && \
      apt-get -y install sudo vim iputils-ping net-tools curl wget dialog software-properties-common apt-utils chrpath git make cmake gcc g++ autoconf autogen libtool scons unzip bzip2 

RUN useradd --create-home -s /bin/bash -m ubuntu && echo "ubuntu:Arm2019" | chpasswd && adduser ubuntu sudo

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

WORKDIR /home/ubuntu
USER ubuntu


#----------------------------------------------------------------------------
# Build the entire Arm NN SDK, a large one time activity
#----------------------------------------------------------------------------
FROM jasonrandrews/ubuntu-arm-base AS sdk

WORKDIR /home/ubuntu
USER ubuntu

# Build machine and target machine linux/arm/v7  linux/arm64 or linux/amd64
ARG TARGETPLATFORM
ARG BUILDPLATFORM

COPY --chown=ubuntu:ubuntu build-armnn.sh /home/ubuntu

RUN if [ "$TARGETPLATFORM" = "linux/arm/v7" ] ; then /home/ubuntu/build-armnn.sh -a armv7a ; else /home/ubuntu/build-armnn.sh ; fi



#----------------------------------------------------------------------------
# Build the developer image to compile C++ applications with Arm NN
# Only libraries and header files are needed
#----------------------------------------------------------------------------
FROM jasonrandrews/ubuntu-arm-base AS dev

WORKDIR /home/ubuntu 
USER ubuntu 

RUN mkdir -p ~/armnn/lib
RUN mkdir -p ~/armnn/include
COPY --from=jasonrandrews/armnn-sdk  /home/ubuntu/armnn-devenv/pkg/install/lib/libprotobuf.so.15 /home/ubuntu/armnn/lib
COPY --from=jasonrandrews/armnn-sdk  /home/ubuntu/armnn-devenv/armnn/build/libarmnnTfParser.so /home/ubuntu/armnn/lib
COPY --from=jasonrandrews/armnn-sdk  /home/ubuntu/armnn-devenv/armnn/build/libarmnn.so /home/ubuntu/armnn/lib
COPY --from=jasonrandrews/armnn-sdk  /home/ubuntu/armnn-devenv/armnn/include/ /home/ubuntu/armnn/include
RUN chrpath -r /home/ubuntu/armnn/lib /home/ubuntu/armnn/lib/libarmnnTfParser.so

COPY --chown=ubuntu:ubuntu clone.sh /home/ubuntu
RUN /home/ubuntu/clone.sh 



#----------------------------------------------------------------------------
# Build an image to just run the application, no source code
#----------------------------------------------------------------------------
FROM jasonrandrews/ubuntu-arm-base AS rel

WORKDIR /home/ubuntu 
USER ubuntu 

COPY --from=dev /home/ubuntu/mnist-demo/mnist_tf_convol /home/ubuntu/
COPY --from=dev /home/ubuntu/mnist-demo/data/ /home/ubuntu/data
COPY --from=dev /home/ubuntu/mnist-demo/model/ /home/ubuntu/model
COPY --from=dev /home/ubuntu/armnn/ /home/ubuntu/armnn

COPY --chown=ubuntu:ubuntu mnist.sh /home/ubuntu/mnist.sh
CMD /home/ubuntu/mnist.sh


