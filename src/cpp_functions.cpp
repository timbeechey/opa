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


/*
 * Returns a matrix of randomly shuffled vectors
 * param n: an integer indicating the number of random reorderings
 * param v: a numeric vector to be shuffled
 * return: a NumericMatrix with nrows = n and ncols = v.length()
 */
// [[Rcpp::export]]
NumericMatrix c_random_shuffles(int n, NumericVector v) {
  NumericMatrix rand_orders(v.length(), n);
  for (int i = 0; i < n; i++) {
    rand_orders(_, i) = sample(v, v.length());
  }
  return(rand_orders);
}

/* Generates pairwise ordinal relations from a vector, consisting of integers
 * from the set {1, 0, -1}. When the pairing_type = "adjacent" option is used,
 * calling ordering() on a vector of length N produces a vector of length N-1.
 * When the pairing_type = "pairwise" option is used, calling ordering() on an
 * N-length vector returns a vector of length ((N-1) * N)/2
 * param: xs a NumericVector
 * param: pairing_type a String, either "adjacent" or "pairwise"
 * param: diff_threshold: a double
 * return: an IntegerVector
*/
// [[Rcpp::export]]
IntegerVector c_ordering(NumericVector xs, String pairing_type, double diff_threshold) {
  if (pairing_type == "pairwise")
    return(c_sign_with_threshold(c_all_diffs(xs), diff_threshold));
  else
    return(c_sign_with_threshold(diff(xs), diff_threshold));
}

/*
 * Calculates a PCC for each reordered vector and compares it to the PCC of the
 * corresponding observed PCC from m. Increments n_perms_greater_eq for each
 * reordering with a PCC >= observed PCC. Returns a list containing the count
 * n_perms_greater_eq and a vector of PCC values.
 * param: perms, a NumericMatrix of random orderings of a data row
 * param: m, a list containing computed PCCs from observed data
 * param: indiv_idx, an int representing the current individual
 * param: H_ord, an IntegerVector of the ordinal relations in the hypothesis
 * return: a list containing a count n_perms_greater_eq and a vector of PCCs
 */
// [[Rcpp::export]]
List c_compare_rand_pccs(NumericMatrix perms, List m, int indiv_idx, IntegerVector H_ord) {
  int n_perms_greater_eq = 0;
  double diff_threshold = m["diff_threshold"];
  String pairing_type = m["pairing_type"];
  NumericVector obs_pcc = m["individual_pccs"];
  NumericVector perm_pcc(perms.ncol());
  LogicalVector comps(H_ord.length());

  for (int i = 0; i < perms.ncol(); i++) {
    NumericVector perm_ordering(H_ord.length());
    perm_ordering = c_ordering(perms(_,i), pairing_type, diff_threshold);
    for (int j = 0; j < perm_ordering.length(); j++) {
      comps[j] = perm_ordering[j] == H_ord[j];
    }
    perm_pcc[i] = mean(comps) * 100;
    if (perm_pcc[i] >= obs_pcc[indiv_idx - 1]) {
      n_perms_greater_eq += 1;
    }
  }
  List out = List::create(Named("n_perms_greater_eq") = n_perms_greater_eq, _["perm_pcc"] = perm_pcc);
  return(out);
}

/*
 * This function is identical to c_compare_rand_pccs() but operates on the list
 * output generated by permn() rather than the matrix output of
 * c_random_shuffles(). Calculates a PCC for each permutation of a vextor and
 * compares it to the PCC of the corresponding observed PCC from m. Increments
 * n_perms_greater_eq for each permutation with a PCC >= observed PCC. Returns a
 * list containing the count n_perms_greater_eq and a vector of PCC values.
 * param: perms, a list containing all permutations of a data row
 * param: m, a list containing computed PCCs from observed data
 * param: indiv_idx, an int representing the current individual
 * param: H_ord, an IntegerVector of the ordinal relations in the hypothesis
 * return: a list containing a count n_perms_greater_eq and a vector of PCCs
 */
// [[Rcpp::export]]
List c_compare_perm_pccs(List perms, List m, int indiv_idx, IntegerVector H_ord) {
  int n_perms_greater_eq = 0;
  double diff_threshold = m["diff_threshold"];
  String pairing_type = m["pairing_type"];
  NumericVector obs_pcc = m["individual_pccs"];
  NumericVector perm_pcc(perms.length());
  LogicalVector comps(H_ord.length());

  for (int i = 0; i < perms.length(); i++) {
    NumericVector perm_ordering(H_ord.length());
    perm_ordering = c_ordering(perms[i], pairing_type, diff_threshold);
    for (int j = 0; j < perm_ordering.length(); j++) {
      comps[j] = perm_ordering[j] == H_ord[j];
    }
    perm_pcc[i] = mean(comps) * 100;
    if (perm_pcc[i] >= obs_pcc[indiv_idx - 1]) {
      n_perms_greater_eq += 1;
    }
  }
  List out = List::create(Named("n_perms_greater_eq") = n_perms_greater_eq, _["perm_pcc"] = perm_pcc);
  return(out);
}
