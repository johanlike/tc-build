#!/usr/bin/env bash

           
# Exit on error
set -e

# Function to show an informational message
function msg() {
    echo -e "\e[1;32m$@\e[0m"
}

#First run scripts need install dependencies
msg "Do you need to install related dependencies? [Y/n]"
read -r -p : input

case $input in
	    [yY][eE][sS]|[yY])
			msg "You select Yes now install dependencies"
			apt update
			apt install bc \
              bison \
              ca-certificates \
              ccache \
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
              zlib1g-dev
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
	--install-folder "installTmp" \

# Build binutils
msg "Building binutils..."
#if [ $(which clang) ] && [ $(which clang++) ]; then
#	export CC=$(which ccache)" clang"
#	export CXX=$(which ccache)" clang++"
#	[ $(which llvm-strip) ] && stripBin=llvm-strip-9
#else
#	export CC=$(which ccache)" gcc"
#	export CXX=$(which ccache)" g++"
#	[ $(which strip) ] && stripBin=strip
#fi
./build-binutils.py \
	--targets arm aarch64 x86_64 \
	--install-folder "installTmp"

# Remove unused products
msg "Removing unused products..."
rm -f installTmp/lib/*.a installTmp/lib/*.la installTmp/lib/clang/*/lib/linux/*.a*

msg "Setting library load paths for portability and"
msg "Stripping remaining products..."
IFS=$'\n'
for f in $(find installTmp -type f -exec file {} \;); do
	if [ -n "$(echo $f | grep 'ELF .* interpreter')" ]; then
		i=$(echo $f | awk '{print $1}'); i=${i: : -1}
		# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
		if [ -d $(dirname $i)/../lib/ldscripts ]; then
			patchelf --set-rpath '$ORIGIN/../../lib:$ORIGIN/../lib' "$i"
		else
			if [ "$(patchelf --print-rpath $i)" != "\$ORIGIN/../../lib:\$ORIGIN/../lib" ]; then
				patchelf --set-rpath '$ORIGIN/../lib' "$i"
			fi
		fi
		# Strip remaining products
		stripBin=llvm-strip-9
		if [ -n "$(echo $f | grep 'not stripped')" ]; then
			${stripBin} --strip-unneeded "$i"
		fi
	elif [ -n "$(echo $f | grep 'ELF .* relocatable')" ]; then
		if [ -n "$(echo $f | grep 'not stripped')" ]; then
			i=$(echo $f | awk '{print $1}');
			${stripBin} --strip-unneeded "${i: : -1}"
		fi
	else
		if [ -n "$(echo $f | grep 'not stripped')" ]; then
			i=$(echo $f | awk '{print $1}');
			${stripBin} --strip-all "${i: : -1}"
		fi
	fi
done

rm -rf ./install
mv installTmp/ ~/Desktop/Clang
