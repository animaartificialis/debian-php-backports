# Patch provenance

Sury never shipped PHP 5.4, so there is no ready-made patch for it.
`0001-Avoid-state-corruption-via-bailout-php54.patch` is a manual port of Sury's
`0261-Avoid-state-corruption-via-bailout.patch` from `php5.6 5.6.40-104` (the same
file as in `targets/debian8-jessie/php5.6-debian/patches/`, sha256
`35b6472ae1b8f90498766811dfa2379d371906a090311962a1df9627677aa7f6`).

Differences from the original, also described in the patch header:

- three hunks in `Zend/zend_alloc.c` are dropped: they change overflow checks that
  only exist in 5.6 (`_safe_emalloc_string()` and two more `safe_address()`
  variants); all four checks that 5.4 does have are converted,
- the `zend_mm_safe_error_ex()` declaration in `Zend/zend_alloc.h` sits after
  `_safe_emalloc()`.

The remaining 12 files apply with unchanged content. The patch was produced as a
`diff -ruN` of the 5.4.45-0+deb7u14 tree (Debian patches applied) before and after.

- Patch sha256: `c3081399f25fd59fac43fd4d2fbc66ad43ea1fb2e158b24953b4525059981500`
- Created: 2026-10-21T21:27:15Z
