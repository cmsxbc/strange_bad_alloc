#!/bin/bash

set -ex

rm -rf *.so
CXX=g++-9
# CXX=g++11 #it's fixed if we use newer gcc

ARCH=skylake-avx512
# ARCH=skylake #it's fixed if we don't compile with avx512

CXX_FLAGS="-std=c++17 -fPIC -O3 -DNDEBUG -march=$ARCH -g"
# CXX_FLAGS="${CXX_FLAGS} -fno-tree-pre" #it's fixed if we disable tree-pre
# CXX_FLAGS="${CXX_FLAGS} -DNO_X86SIMDSORT" #it's fixed if we don't use x86simdsort

python -m pip install pybind11==2.10.1
# python -m pip install pybind11==2.10.1 #it's fixed if pybind11 <= 2.10.0
CXX_FLAGS="${CXX_FLAGS} $(python -m pybind11 --includes)"


${CXX} ${CXX_FLAGS} -shared -o wtf$(python3-config --extension-suffix) main.cc
python test.py
