// Generated by cpp11: do not edit by hand
// clang-format off

#include <cpp11/R.hpp>
#include <Rcpp.h>
using namespace Rcpp;
#include "cpp11/declarations.hpp"
#include <R_ext/Visibility.h>

// cpp_functions.cpp
void fun();
extern "C" SEXP _opa_fun() {
  BEGIN_CPP11
    fun();
    return R_NilValue;
  END_CPP11
}

extern "C" {
/* .Call calls */
extern SEXP _opa_c_all_diffs(SEXP);
extern SEXP _opa_c_calc_cvalues(SEXP, SEXP);
extern SEXP _opa_c_conform(SEXP, SEXP);
extern SEXP _opa_c_ordering(SEXP, SEXP, SEXP);
extern SEXP _opa_c_row_pcc(SEXP, SEXP, SEXP, SEXP);
extern SEXP _opa_c_sign_with_threshold(SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"_opa_c_all_diffs",           (DL_FUNC) &_opa_c_all_diffs,           1},
    {"_opa_c_calc_cvalues",        (DL_FUNC) &_opa_c_calc_cvalues,        2},
    {"_opa_c_conform",             (DL_FUNC) &_opa_c_conform,             2},
    {"_opa_c_ordering",            (DL_FUNC) &_opa_c_ordering,            3},
    {"_opa_c_row_pcc",             (DL_FUNC) &_opa_c_row_pcc,             4},
    {"_opa_c_sign_with_threshold", (DL_FUNC) &_opa_c_sign_with_threshold, 2},
    {"_opa_fun",                   (DL_FUNC) &_opa_fun,                   0},
    {NULL, NULL, 0}
};
}

extern "C" attribute_visible void R_init_opa(DllInfo* dll){
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
