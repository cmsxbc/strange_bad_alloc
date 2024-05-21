#include <iostream>
#include <unordered_map>
#include <string>
#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>

#ifndef NO_X86SIMDSORT
#include "x86-simd-sort/src/x86simdsort-static-incl.h"
#endif

namespace py = pybind11;

class WTF {
public:
    double calc(std::unordered_map<std::string, std::tuple<size_t, double*>> feature_ptrs) {
        double sum = 0.0;
        for (auto &[name, tp]: feature_ptrs) {
#ifndef NO_X86SIMDSORT
            auto arg = x86simdsortStatic::argsort(std::get<1>(tp), std::get<0>(tp), true);
            sum += std::get<1>(tp)[arg[0]];
#else
            sum += std::get<1>(tp)[0];
#endif
        }
        return sum;
    }
};


PYBIND11_MODULE(wtf, m) {
    py::class_<WTF>(m, "WTF")
        .def(py::init<>())
        .def("calculate", [](WTF& self, std::unordered_map<std::string, py::array_t<double, py::array::c_style>> feature_dict) {
                std::unordered_map<std::string, std::tuple<size_t, double*>> feature_ptrs;
                for (auto& [name, array]: feature_dict) {
                    feature_ptrs[name] = std::make_tuple(array.size(), static_cast<double*>(array.request().ptr));
                }
                return self.calc(feature_ptrs);
        });
}
