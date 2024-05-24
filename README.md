# strange_bad_alloc

## TL;DR

`g++-9` with `-O2` above will compile the `argsort_n_vec`(of x86-simd-sort) with some mmx instructions, but won't clear x87 fpu state.

And `long double`, which used x87 instructions default, is used in `prime_hashtable_policy` which is used by `unorderd_map`.

If we call `unordered_map::rehash` after `argsort/argselect`(of `x86-simd-sort`), `rehash(size_t(-1))` was performed, and `std::bad_alloc` was raised.

