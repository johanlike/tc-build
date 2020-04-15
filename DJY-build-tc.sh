#!/usr/bin/env bash

# Exit on error
set -e

# Function to show an informational message
function msg() {
    echo -e "\e[1;32m$@\e[0m"
}

#Install Clang Path
install=~/Desktop/Clang

#First run scripts need install dependencies
msg "Do you need to install related dependencies? [Y/n]"
read -r -p : input

case $input in
	    [yY][eE][sS]|[yY])
			msg "You select Yes now $install dependencies"
			  apt update
			  apt install bc \
              bison \
              ca-certificates \
              ccache \
              patchelf \
              clang \
              cmake \
              curl \
              file \
              flex \
              gcc \
              g++ \
              git \
              libelf-dev \
              libssl-dev \
              make \
              ninja-build \
              python3 \
              texinfo \
              u-boot-tools \
              xz-utils \
              zlib1g-dev -y
			;;

	    [nN][oO]|[nN])
			msg "You select No now build llvm"	       	
			;;

	    *)
			msg "You have Invalid input..."
			;;
	esac



 

# Build LLVM
msg "Building LLVM..."
./build-llvm.py \
    --shallow-clone \
    --pgo \
    --lto thin \
    --clang-vendor "DJY-$(date +%F-%T)" \
	--targets "ARM;AArch64;X86" \
	--update \
	--incremental \
	--build-stage1-only \
	--install-stage1-only \
	--install-folder "$install" \

# Build binutils
msg "Building binutils..."
./build-binutils.py \
	--targets arm aarch64 x86_64 \
	--install-folder "$install"

# Remove unused products
msg "Removing unused products..."
rm -f $install/lib/*.a $install/lib/*.la $install/lib/clang/*/lib/linux/*.a* 
rm -rf $install/include


# Strip remaining products
msg "Stripping remaining products..."
for f in $(find $install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
	strip ${f: : -1}
done

# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
msg "Setting library load paths for portability..."
for bin in $(find $install -mindepth 2 -maxdepth 3 -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}'); do
	# Remove last character from file output (':')
	bin="${bin: : -1}"

	echo "$bin"
	patchelf --set-rpath '$ORIGIN/../lib' "$bin"
done


