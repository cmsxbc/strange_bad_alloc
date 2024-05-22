#!/bin/bash

set -ex

CXX="g++-9"
ARCH="skylake-avx512"
CXX_FLAGS="-std=c++17 -Wall -O2 -march=$ARCH"

src='
#include <unordered_map> // map is ok
#include "x86-simd-sort/src/x86simdsort-static-incl.h"

double calc(size_t size) {
    auto ptr = new double[size]{0};
    //auto arg = x86simdsortStatic::argselect(ptr, 0, size);
    auto arg = new size_t[size]{0};
    for (size_t i = 0; i < size; i++) {
        arg[i] = i;
    }
    argsort_n_vec<zmm_vector<double>, zmm_vector<size_t>, 32>(ptr, arg, (int32_t)size);
    auto ret = ptr[arg[0]];
    delete[] ptr;
    delete[] arg;
    return ret;
}


int main() {
    std::unordered_map<size_t, size_t> amap;
    amap.clear();
    calc(65); // [65, 256]
    amap.rehash(1);
}
'

echo "$src" > main.cc
$CXX $CXX_FLAGS -o main -g main.cc
./main
