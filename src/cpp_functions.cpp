/*
 * <opa: An Implementation of Ordinal Pattern Analysis.>
 * Copyright (C) <2022>  <Timothy Beechey; tim.beechey@protonmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#include <Rcpp.h>
using namespace Rcpp;

/*
 * Returns the sign of every element of a vector conditional on a
 * user-supplied difference threshold diff_threshold.
 * Returns 1 for any positive input value larger than diff_threshold.
 * Returns -1 for any negative input value smaller than -diff_threshold.
 * Returns 0 for any input value that is both smaller than diff_threshold
 * and larger than -diff_threshold. This function is equivalent to R's
 * built-in sign() function when diff_threshold = 0.
 *
 * param: xs a numeric vector
 * param: diff_threshold a floating point number
 * return: an integer from the set {1, 0, -1}.
 */
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

/*
 * Calculates the difference between every pair of elements in a vector.
 * This function is called when the pairing_type = "pairwise" option is used.
 * When the pairing_type = "adjacent" option is used, R's built-in diff()
 * function is used instead. For an input vector of length N, the output vector
 * has length equal to the Nth-1 triangular number, calculated as (N-1 * N) / 2.
 * param xs: a numeric vector
 * return: a numeric vector
 */
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
