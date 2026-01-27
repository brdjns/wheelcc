#!/usr/bin/env bash

KERNEL_NAME="$(uname -s)"
PACKAGE_TEST="$(dirname $(readlink -f ${0}))"
cd $(dirname ${PACKAGE_TEST})/build/

CC="gcc"
CXX="g++"
if [[ "${KERNEL_NAME}" == "Darwin"* ]]; then
    CC="clang"
    CXX="clang++"
elif [[ "${KERNEL_NAME}" == "FreeBSD"* ]]; then
    CC="clang"
    CXX="clang++"
fi

./build_preset.sh ${CC}
if [ ${?} -ne 0 ]; then exit 1; fi

BUILD_CPP="OFF"
export CC=$(which ${CC})
if [ "${1}" = "--cpp" ]; then
    BUILD_CPP="ON"
    export CXX=$(which ${CXX})
fi

cmake -G "Unix Makefiles" -S . -B test/ -DCMAKE_BUILD_TYPE=Release \
    -D__NDEBUG__=OFF -DBUILD_CPP=${BUILD_CPP}
if [ ${?} -ne 0 ]; then exit 1; fi

cd test/
cmake --build . --config Release
if [ ${?} -ne 0 ]; then exit 1; fi

exit 0
