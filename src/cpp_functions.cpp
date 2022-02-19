#include <Rcpp.h>
using namespace Rcpp;

// Returns the sign of every element of a vector conditional on a
// user-supplied difference threshold diff_threshold.
// Returns 1 for any positive input value larger than diff_threshold.
// Returns -1 for any negative input value smaller than -diff_threshold.
// Returns 0 for any input value that is both smaller than diff_threshold
// and larger than -diff_threshold. This function is equivalent to R's
// built-in sign() function when diff_threshold = 0.
//
// param: xs a numeric vector
// param: diff_threshold a floating point number
// return: an integer from the set {1, 0, -1}.
// [[Rcpp::export]]
IntegerVector c_sign_with_threshold(NumericVector xs, double diff_threshold) {
  IntegerVector sign_vector(xs.length());
  for (int i = 0; i < xs.length(); i++) {
    if (NumericVector::is_na(xs[i])) {
        sign_vector[i] = NA_INTEGER;
    } else if (xs[i] > diff_threshold) {
        sign_vector[i] = 1;
    } else if (xs[i] < -diff_threshold) {
        sign_vector[i] = -1;
    } else {
        sign_vector[i] = 0;
    }
  }
  return(sign_vector);
}

// Calculates the difference between every pair of elements in a vector.
// This function is called when the pairing_type = "pairwise" option is used.
// When the pairing_type = "adjacent" option is used, R's built-in diff()
// function is used instead. For an input vector of length N, the output vector
// has length equal to the Nth-1 triangular number, calculated as (N-1 * N) / 2.
// param xs: a numeric vector
// return: a numeric vector
// [[Rcpp::export]]
NumericVector c_all_diffs(NumericVector xs) {

  // Initialize variables
  int count = 0;
  // Calculate the length of the vector as the Nth-1 triangular number.
  // This is needed to pre-size an empty vector.
  int n_pairs = ((xs.length() - 1) * xs.length()) / 2;
  // Create empty vector of the correct size to hold all pairwise differences.
  NumericVector diffs(n_pairs);

  // Fill the diffs vector with the difference between each pair of
  // vector elements
  for (int i = 0; i < xs.length(); i++) {
    for (int j = i + 1; j < xs.length(); j++) {
      diffs[count] = xs[j] - xs[i];
      count++;
    }
  }
  return(diffs);
}
