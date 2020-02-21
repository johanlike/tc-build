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
            zlib1g-dev
            
./build-llvm.py \
	-I "/root/Desktop/Clang" \
      --clang-vendor "DJY" \
      --projects "clang;compiler-rt;lld;polly" \
      --targets "ARM;AArch64;X86" \
      --shallow-clone \
      --pgo \
      --lto full