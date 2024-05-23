#!/bin/bash

set -e

CXX="${CXX:-g++-9}"
SDE="${SDE:-}"
ARCH="skylake-avx512"
CXX_FLAGS="-std=c++17 -Wall -O2 -march=$ARCH"
BASE_DIR="$(realpath "$(dirname "$0")")/"
if [[ "$BASE_DIR" =~ /proc/ ]];then
    BASE_DIR=''
fi

function compile() {
    local patch
    if [[ -n "$1" ]];then
        patch='asm volatile ("FNINIT");'
    fi
    $CXX $CXX_FLAGS -x c++ -o poc.minimal - << END
#include <unordered_map> // map is ok
#include "${BASE_DIR}x86-simd-sort/src/x86simdsort-static-incl.h"

double calc(size_t size) {
    auto ptr = new double[size]{0};
    auto arg = x86simdsortStatic::argselect(ptr, 0, size);
    auto ret = ptr[arg[0]];
    delete[] ptr;
    ${patch}
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
        gdb \
            -ex 'b *main+136' \
            -ex 'r' \
            -ex 'print $st0' \
            -ex 'print *(size_t *)($rsp+0x8)' \
            -ex 'si' \
            -ex 'print $st0' \
            --batch --silent ./poc.minimal | grep '\$'
    fi
}


compile
echo "compile crash done...."
if $SDE ./poc.minimal;then
    echo "poc failed.... tell me please"
    exit 1
else
    observe
    echo "crash as expected!"
fi
rm ./poc.minimal

compile 1
echo "compile patch done...."
if ! $SDE ./poc.minimal;then
    echo "patch failed.... tell me please"
    exit 1
else
    observe
    echo "patch work as expected!"
fi
rm ./poc.minimal
