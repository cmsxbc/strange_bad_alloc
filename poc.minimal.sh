#!/bin/bash

set -e

CXX="${CXX:-g++-9}"
SDE="${SDE:-}"
ARCH="skylake-avx512"
CXX_FLAGS="-std=c++17 -Wall -O2 -march=$ARCH"
BASE_DIR="$(realpath "$(dirname "$0")")/"
EXE_NAME="./poc.minimal"
if [[ "$BASE_DIR" =~ /proc/ ]];then
    BASE_DIR=''
fi
CRASH_NUM=10

echo "test gcc version: $($CXX -dumpversion)"


function compile() {
    local patch
    if [[ -n "$1" ]];then
        patch="-DPATCH"
    fi
    $CXX $CXX_FLAGS $patch -x c++ -o "$EXE_NAME" - << END
#include <cstdio>
#include "${BASE_DIR}x86-simd-sort/src/x86simdsort-static-incl.h"

double calc(size_t size) {
    auto ptr = new double[size]{1};
    auto arg = x86simdsortStatic::argsort(ptr, size, false, true);
#ifdef PATCH
    // asm volatile ("FNINIT");
    asm volatile ("EMMS");
#endif
    auto ret = ptr[arg[0]];
    delete[] ptr;
    return ret;
}

int main(int argc, const char * argv[]) {
    double ret = calc(256); // [65, 256]
    size_t a = std::atoll(argv[1]);
    double ret_a = a / ret;
    long double lret_a = a / (long double)ret;
    printf("ret=%lf, %lu/ret=%lf, %lu/(long double)ret=%Lf\n", ret, a, ret_a, a, lret_a);
    return std::isnan(lret_a);
}
END
}

function observe() {
    if type gdb > /dev/null;then
        local bp
        bp="$(objdump -d --prefix-address "$EXE_NAME" | grep fildll | head -1 | awk '{$2 = substr($2, 2, length($2)-2); print $2}')"
        echo 'tracking $st0 with gdb'
        gdb \
            -ex "b *$bp" \
            -ex 'r' \
            -ex 'print "ST(0) before convert a"' \
            -ex 'print $st0' \
            -ex 'si' \
            -ex 'print "ST(0) after convert a"' \
            -ex 'print $st0' \
            --batch --silent --arg "$EXE_NAME" $CRASH_NUM | grep '\$'
    fi
}


compile
echo "compile crash done...."
if $SDE "$EXE_NAME" $CRASH_NUM;then
    echo "poc failed.... tell me please"
    exit 1
else
    observe
    echo "crash as expected!"
fi
rm "$EXE_NAME"

compile 1
echo "compile patch done...."
if ! $SDE "$EXE_NAME" $CRASH_NUM;then
    echo "patch failed.... tell me please"
    exit 1
else
    observe
    echo "patch work as expected!"
fi
rm "$EXE_NAME"
