/*
 * opa: An Implementation of Ordinal Pattern Analysis.
 * Copyright (C) 2022 Timothy Beechey (tim.beechey@proton.me)
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
#include <cpp11.hpp>

using namespace Rcpp;
using namespace cpp11;

[[cpp11::register]]
void fun() {}


/*
 * Returns the sign of every element of a vector conditional on a
 * user-supplied difference threshold diff_threshold.
 * Returns 1 for any positive input value larger than diff_threshold.
 * Returns -1 for any negative input value smaller than -diff_threshold.
 * Returns 0 for any input value that is both smaller than diff_threshold
 * and larger than -diff_threshold. This function is equivalent to R's
 * built-in sign() function when diff_threshold = 0.
 *
 * param: xs, a NumericVector.
 * param: diff_threshold, a double.
 * return: an int from the set {1, 0, -1}.
 */
// [[Rcpp::export]]
IntegerVector c_sign_with_threshold(NumericVector xs, double diff_threshold) {
  IntegerVector sign_vector(xs.length());
  for (int i = 0; i < xs.length(); i++) {
    if (is_na(xs[i])) {
        sign_vector[i] = NA_INTEGER;
    } else if (xs[i] > diff_threshold) {
        sign_vector[i] = 1;
    } else if (xs[i] < -diff_threshold) {
        sign_vector[i] = -1;
    } else {
        sign_vector[i] = 0;
    }
  }
  return sign_vector;
}


/*
 * Calculate the difference between every pair of elements in a vector.
 * This function is called when the pairing_type = "pairwise" option is used.
 * When the pairing_type = "adjacent" option is used, R's built-in diff()
 * function is used instead. For an input vector of length N, the output vector
 * has length equal to the Nth-1 triangular number, calculated as (N-1 * N) / 2.
 * param: xs, a NumericVector.
 * return: a NumericVector.
 */
// [[Rcpp::export]]
NumericVector c_all_diffs(NumericVector xs) {
  // Initialize variables
  int count{0};
  // Calculate the length of the vector as the Nth-1 triangular number.
  // This is needed to pre-size an empty vector.
  // Note that brace initialisation of n_pairs catches narrowing from R's
  // long long int if n_pairs is initialised with type int or size_t.
  long long n_pairs{((xs.length() - 1) * xs.length()) / 2};
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
  return diffs;
}


/* Generate pairwise ordinal relations from a vector, consisting of integers
 * from the set {1, 0, -1}. When the pairing_type = "adjacent" option is used,
 * calling c_ordering() on a vector of length N produces a vector of length N-1.
 * When the pairing_type = "pairwise" option is used, calling c_ordering() on an
 * N-length vector returns a vector of length ((N-1) * N)/2
 * param: xs, a NumericVector.
 * param: pairing_type, a String, either "adjacent" or "pairwise".
 * param: diff_threshold, a positive double.
 * return: an IntegerVector.
*/
// [[Rcpp::export]]
IntegerVector c_ordering(NumericVector xs, String pairing_type, float diff_threshold) {
  if (pairing_type == "pairwise")
    return(c_sign_with_threshold(c_all_diffs(xs), diff_threshold));
  else
    return c_sign_with_threshold(diff(xs), diff_threshold);
}

/*
 * Calculate a PCC for each reordered vector and compare it to the corresponding
 * observed PCC from m. Increments n_perms_greater_eq for each reordering with a
 * PCC >= observed PCC. Returns a list containing the count n_perms_greater_eq
 * and a vector of PCC values.
 * param: perms, a NumericMatrix of permutations or random orderings of a vector
 * param: m, a List containing computed PCCs from observed data
 * param: indiv_idx, an int representing the current individual
 * param: H_ord, an IntegerVector of the ordinal relations in the hypothesis
 * return: a List containing a count n_perms_greater_eq and a vector of PCCs
 */
// [[Rcpp::export]]
List c_compare_perm_pccs(NumericMatrix perms, List m, int indiv_idx, IntegerVector H_ord) {
  int n_perms_greater_eq{0};
  double diff_threshold{m["diff_threshold"]};
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
  return out;
}


// // [[Rcpp::export]]
// List c_cvalues(List pcc_out, int nreps) {
//   Function c_row_pcc("row_pcc");
//   NumericMatrix dat = pcc_out["data"];
//   NumericVector hypothesis = pcc_out["hypothesis"];
//   String pairing_type = pcc_out["pairing_type"];
//   double diff_threshold = pcc_out["diff_threshold"];
//   NumericVector individual_pccs = pcc_out["individual_pccs"];
//   double obs_group_pcc = pcc_out["group_pcc"];
//
//   // vector to store each random group-level PCC
//   NumericVector rand_group_pccs(nreps);
//   // vector with 1 element for each individual to tally rand indiv pccs >= obs indiv pcc
//   NumericVector indiv_rand_pcc_geq_obs_pcc(dat.nrow());
//   NumericVector individual_cvals(dat.nrow());
//
//   for (int i = 0; i < nreps; i++) {
//     NumericVector rand_indiv_pccs(dat.nrow());
//     for (int j = 0; j < dat.nrow(); j++) {
//       NumericVector current_row = dat(j,_);
//       List rand_row_pcc = c_row_pcc(sample(current_row, current_row.length()), hypothesis, pairing_type, diff_threshold);
//       double rand_indiv_pcc = rand_row_pcc["pcc"];
//       rand_indiv_pccs[j] = rand_indiv_pcc;
//       if (rand_indiv_pccs[j] >= individual_pccs[j]) {
//         indiv_rand_pcc_geq_obs_pcc[j] = indiv_rand_pcc_geq_obs_pcc[j] + 1;
//       }
//     }
//     rand_group_pccs[i] = mean(rand_indiv_pccs);
//   }
//
//   for (int k = 0; k < individual_cvals.length(); k++) {
//     individual_cvals[k] = double(indiv_rand_pcc_geq_obs_pcc[k]) / double(nreps);
//   }
//
//   double group_cval = sum(rand_group_pccs >= obs_group_pcc) / double(nreps);
//
//   List out = List::create(Named("group_cval") = group_cval, _["individual_cvals"] = individual_cvals);
//   return out;
// }

