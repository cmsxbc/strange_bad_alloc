#!/bin/bash

set -e

CXX="${CXX:-g++-9}"
SDE="${SDE:-}"
ARCH="skylake-avx512"
CXX_FLAGS="-std=c++17 -Wall -O2 -march=$ARCH"
BASE_DIR="$(realpath "$(dirname "$0")")/"
EXE_NAME="./poc"
if [[ "$BASE_DIR" =~ /proc/ ]];then
    BASE_DIR=''
fi

function compile() {
    local patch
    if [[ -n "$1" ]];then
        patch="-DPATCH"
    fi
    $CXX $CXX_FLAGS $patch -x c++ -o "${EXE_NAME}" - << END
#include <unordered_map> // map is ok
#include "${BASE_DIR}x86-simd-sort/src/x86simdsort-static-incl.h"

double calc(size_t size) {
    auto ptr = new double[size]{0};
    auto arg = x86simdsortStatic::argselect(ptr, 0, size);
#ifdef PATCH
    asm volatile ("FNINIT");
#endif
    auto ret = ptr[arg[0]];
    delete[] ptr;
    return ret;
}

int main() {
    std::unordered_map<size_t, size_t> amap;
    amap.clear();
    calc(65); // [65, 256]
    amap.rehash(1);
}
END
}

function observe() {
    if type gdb > /dev/null;then
        local bp
        bp="$(objdump -d --prefix-address "$EXE_NAME" | grep fildll | awk '{$2 = substr($2, 2, length($2)-2); print $2}')"
        echo "tracking ST(0)"
        gdb \
            -ex "b *$bp" \
            -ex 'r' \
            -ex 'print "ST(0) before do size_t to long double convert" ' \
            -ex 'print $st0' \
            -ex 'print "The size_t value to be converted" ' \
            -ex 'print *(size_t *)($rsp+0x8)' \
            -ex 'print "ST(0) after do size_t to long double convert" ' \
            -ex 'si' \
            -ex 'print $st0' \
            --batch --silent "$EXE_NAME" | grep '\$'
    fi
}


compile
echo "compile crash done...."
if $SDE "$EXE_NAME";then
    echo "poc failed.... tell me please"
    exit 1
else
    observe
    echo "crash as expected!"
fi
rm "$EXE_NAME"

compile 1
echo "compile patch done...."
if ! $SDE "$EXE_NAME";then
    echo "patch failed.... tell me please"
    exit 1
else
    observe
    echo "patch work as expected!"
fi
rm "$EXE_NAME"
