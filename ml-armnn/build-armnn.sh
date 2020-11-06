#!/bin/bash

#
# Copyright (c) 2018-2019 Arm Limited. All rights reserved.
#

#
# Script to build all of the required software for the Arm NN examples
#

usage() { 
    echo "Usage: $0 [-a <armv7a|arm64-v8a>] [-o <0|1> ]" 1>&2 
    echo "   default arch is arm64-v8a " 1>&2
    echo "   -o option will enable or disable OpenCL when cross compiling" 1>&2
    echo "      native compile will enable OpenCL if /dev/mali is found and -o is not used" 1>&2
    exit 1 
}

# Simple command line arguments
while getopts ":a:o:h" opt; do
    case "${opt}" in
        a)
            Arch=${OPTARG}
            [ $Arch = "armv7a" -o $Arch = "arm64-v8a" ] || usage
            ;;
        o)
            OpenCL=${OPTARG}
            ;;
        h)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# make sure machien is Arm
if [ `uname -m` = "x86_64" ]; then
    echo "Not running on an Arm machine"
    exit 
fi

# save history to logfile
exec > >(tee -i logfile)
exec 2>&1

echo "Building Arm NN in $HOME/armnn-devenv"

# Start from home directory
cd $HOME 

# Gator daemon source
git clone https://github.com/ARM-software/gator.git

# if nothing, found make a new diectory
[ -d armnn-devenv ] || mkdir armnn-devenv


# check for previous installation, HiKey 960 is done as a mount point so don't 
# delete all from top level, drop down 1 level
while [ -d armnn-devenv/pkg ]; do
    read -p "Do you wish to remove the existing armnn-devenv build environment? " yn
    case $yn in
        [Yy]*) rm -rf armnn-devenv/pkg armnn-devenv/ComputeLibrary armnn-devenv/armnn ; break ;;
        [Nn]*) echo "Exiting " ; exit;;
        *) echo "Please answer yes or no.";;
    esac
done

cd armnn-devenv 

# number of CPUs and memory size for make -j
NPROC=`grep -c ^processor /proc/cpuinfo`
MEM=`awk '/MemTotal/ {print $2}' /proc/meminfo`

# check for Mali device node
[ -z "$OpenCL" ] && [ -c /dev/mali? ] && OpenCL=1 || OpenCL=0 

# check for Armv8 or Armv7
# don't override command line and default to aarch64
[ -z "$Arch" ] && Arch=`uname -m`

if [ $Arch = "armv7l" ] || [ $Arch = "armv7a" ]; then
    Arch=armv7a
    PREFIX=arm-linux-gnueabihf-
else
    Arch=arm64-v8a
    PREFIX=aarch64-linux-gnu-
fi


# Boost

mkdir -p pkg/boost 
echo "building boost"
pushd pkg/boost

wget https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.bz2
tar xf boost_1_64_0.tar.bz2
cd boost_1_64_0
./bootstrap.sh --prefix=$HOME/armnn-devenv/pkg/boost/install


./b2 install link=static cxxflags=-fPIC --with-filesystem --with-test --with-log --with-program_options --prefix=$HOME/armnn-devenv/pkg/boost/install 

popd


# Arm Compute Library 
# latest version
git clone https://github.com/ARM-software/ComputeLibrary.git

echo "building Arm CL"
pushd ComputeLibrary

# check gcc version in case adjustments are needed based on compiler
VER=`gcc -dumpversion | awk 'BEGIN{FS="."} {print $1}'`
echo "gcc version is $VER"

scons arch=$Arch neon=1 opencl=$OpenCL embed_kernels=$OpenCL Werror=0 \
  extra_cxx_flags="-fPIC" benchmark_tests=0 examples=0 validation_tests=0 \
  os=linux -j $NPROC

popd

# TensorFlow and Google protobuf
# Latest TensorFlow had a problem, udpate branch as needed

pushd pkg
mkdir install
git clone --branch 3.5.x https://github.com/protocolbuffers/protobuf.git
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
# need specific version of tensorflow
git checkout a0043f9262dc1b0e7dc4bdf3a7f0ef0bebc4891e
cd ../

# build Protobuf
cd protobuf
./autogen.sh


mkdir build ; cd build
../configure --prefix=$HOME/armnn-devenv/pkg/install 

make -j $NPROC
make install 

popd

# Arm NN
# latest version
git clone https://github.com/ARM-software/armnn.git

pushd pkg/tensorflow/

$HOME/armnn-devenv/armnn/scripts/generate_tensorflow_protobuf.sh $HOME/armnn-devenv/pkg/tensorflow-protobuf $HOME/armnn-devenv/pkg/install

popd

# Arm NN
pushd armnn
mkdir build ; cd build


cmake ..  \
-DCMAKE_C_COMPILER_FLAGS=-fPIC \
-DARMCOMPUTE_ROOT=$HOME/armnn-devenv/ComputeLibrary/ \
-DARMCOMPUTE_BUILD_DIR=$HOME/armnn-devenv/ComputeLibrary/build \
-DBOOST_ROOT=$HOME/armnn-devenv/pkg/boost/install/ \
-DTF_GENERATED_SOURCES=$HOME/armnn-devenv/pkg/tensorflow-protobuf/  \
-DBUILD_TF_PARSER=1 \
-DPROTOBUF_ROOT=$HOME/armnn-devenv/pkg/install   \
-DPROTOBUF_INCLUDE_DIRS=$HOME/armnn-devenv/pkg/install/include   \
-DARMCOMPUTENEON=1  \
-DARMCOMPUTECL=$OpenCL \
-DPROTOBUF_LIBRARY_DEBUG=$HOME/armnn-devenv/pkg/install/lib/libprotobuf.so \
-DPROTOBUF_LIBRARY_RELEASE=$HOME/armnn-devenv/pkg/install/lib/libprotobuf.so \
-DPROFILING_BACKEND_STREAMLINE=1 \
-DCMAKE_CXX_FLAGS="-Wno-error=sign-conversion" \
-DGATOR_ROOT=$HOME/gator \
-DCMAKE_BUILD_TYPE=Debug

if [ $Arch = "armv7l" ] || [ $MEM -lt 2000000 ]; then
    # avoid running out of memory on smaller systems 
    make
else
    make -j $NPROC
fi
popd

echo "done, everything in armnn-devenv/"

echo $Arch > ~/.arch

cd $HOME


