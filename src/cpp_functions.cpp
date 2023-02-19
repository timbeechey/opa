// opa: An Implementation of Ordinal Pattern Analysis.
// Copyright (C) 2023 Timothy Beechey (tim.beechey@proton.me)

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


#include <Rcpp.h>
#include <algorithm>
#include <random>

using namespace Rcpp;

// Skip elements in a hypothesis vector that correspond to NA values in the
// data vector. This function is called when the data vector contains at least
// one NA value.
// @param xs, a NumericVector.
// @param h, a NumericVector.
// @return a NumericVector.
// [[Rcpp::export]]
NumericVector conform(NumericVector xs, NumericVector h) {
  size_t count {};
  for (double x : xs) {
    std::isnan(x) ? count : count++;
  }
  NumericVector h_trimmed(count);
  size_t idx {};
  for (size_t x {}; x < xs.length(); x++) {
    if (!std::isnan(xs[x])) {
      h_trimmed[idx] = h[x];
      idx++;
    }
  }
  return h_trimmed;
}


// Returns the sign of every element of a vector conditional on a
// user-supplied difference threshold diff_threshold.
// Returns 1 for any positive input value larger than diff_threshold.
// Returns -1 for any negative input value smaller than -diff_threshold.
// Returns 0 for any input value that is both smaller than diff_threshold
// and larger than -diff_threshold. This function is equivalent to R's
// built-in sign() function when diff_threshold = 0.
// @param xs, a NumericVector.
// @param diff_threshold, a double.
// @return an int from the set {1, 0, -1}.
// [[Rcpp::export]]
IntegerVector sign_with_threshold(NumericVector xs, double diff_threshold) {
  IntegerVector sign_vector(xs.length());
  for (size_t i {}; i < xs.length(); i++) {
    if (std::isnan(xs[i])) {
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



// Calculate the difference between every pair of elements in a vector.
// This function is called when the pairing_type = "pairwise" option is used.
// When the pairing_type = "adjacent" option is used, R's built-in diff()
// function is used instead. For an input vector of length N, the output vector
// has length equal to the Nth-1 triangular number, calculated as (N-1 * N) / 2.
// @param xs, a NumericVector.
// @return a NumericVector.
// [[Rcpp::export]]
NumericVector all_diffs(NumericVector xs) {
  size_t count {};
  // Calculate the length of the vector as the Nth-1 triangular number
  auto n_pairs {((xs.length() - 1) * xs.length()) / 2};
  NumericVector diffs(n_pairs);
  // Fill the diffs vector with the difference between each pair of vector elements
  for (size_t i {}; i < xs.length(); i++) {
    for (size_t j {i+1}; j < xs.length(); j++) {
      diffs[count] = xs[j] - xs[i];
      count++;
    }
  }
  return diffs;
}


// Generate pairwise ordinal relations from a vector, consisting of integers
// from the set {1, 0, -1}. When the pairing_type = "adjacent" option is used,
// calling ordering() on a vector of length N produces a vector of length N-1.
// When the pairing_type = "pairwise" option is used, calling ordering() on an
// N-length vector returns a vector of length ((N-1) * N)/2
// @param xs, a NumericVector.
// @param pairing_type, a String, either "adjacent" or "pairwise".
// @param diff_threshold, a positive double.
// @return an IntegerVector.
// [[Rcpp::export]]
IntegerVector ordering(NumericVector xs, String pairing_type, float diff_threshold) {
  if (pairing_type == "pairwise")
    return(sign_with_threshold(all_diffs(xs), diff_threshold));
  else
    return sign_with_threshold(diff(xs), diff_threshold);
}


// Calculate the percentage of correct classifications for a single row of data.
// @param xs, a NumericVector.
// @param h, a NumericVector.
// @param pairing_type, a String, either "adjacent" or "pairwise".
// @param diff_threshold, a non-negative double.
// [[Rcpp::export]]
List row_pcc(NumericVector xs, NumericVector h, String pairing_type, double diff_threshold) {
  NumericVector hypothesis_no_nas = any(is_na(xs)).is_true() ? conform(xs, h) : h;
  IntegerVector hypothesis_ordering = ordering(hypothesis_no_nas, pairing_type, 0);
  IntegerVector row_ordering = ordering(na_omit(xs), pairing_type, diff_threshold);
  LogicalVector match(row_ordering.length());
  for (size_t i{}; i < row_ordering.length(); i++) {
    match[i] = row_ordering[i] == hypothesis_ordering[i];
  }
  long n_pairs {match.length()};
  long correct_pairs {sum(match)};
  double pcc {(correct_pairs/(double)n_pairs) * 100};
  return List::create(_["n_pairs"] = n_pairs,
                      _["correct_pairs"] = correct_pairs,
                      _["pcc"] = pcc);
}


// Calculate the percentage of correct classifications for each row of data,
// and the PCC of the group as a whole.
// @param dat, a NumericMatrix.
// @param h, a NumericVector.
// @param pairing_type, a String, either "adjacent" or "pairwise".
// @param diff_threshold, a non-negative double.
// @return a List.
// [[Rcpp::export]]
List pcc(NumericMatrix dat, NumericVector h, String pairing_type, double diff_threshold) {
  NumericVector individual_pccs(dat.nrow());
  size_t total_pairs {};
  size_t correct_pairs {};

  for (int r{}; r < dat.nrow(); r++) {
    List result = row_pcc(dat(r,_), h, pairing_type, diff_threshold);
    size_t result_n_pairs {result["n_pairs"]};
    size_t result_correct_pairs {result["correct_pairs"]};

    individual_pccs[r] = result["pcc"];
    total_pairs += result_n_pairs;
    correct_pairs += result_correct_pairs;
  }
  
  double group_pcc {(correct_pairs / (double)total_pairs) * 100};

  return List::create(_["group_pcc"] = group_pcc,
                      _["individual_pccs"] = individual_pccs,
                      _["total_pairs"] = total_pairs,
                      _["correct_pairs"] = correct_pairs,
                      _["data"] = dat,
                      _["hypothesis"] = h,
                      _["pairing_type"] = pairing_type,
                      _["diff_threshold"] = diff_threshold);
}

// Calculate the chance value for each individual in a matrix of data, and
// the chance value for the group as a whole.
// @param pcc_out, a List.
// @param nreps, an integer.
// @return a List.
// [[Rcpp::export]]
List calc_cvalues(List pcc_out, int nreps) {
  NumericMatrix dat = pcc_out["data"];
  NumericVector hypothesis = pcc_out["hypothesis"];
  String pairing_type {pcc_out["pairing_type"]};
  double diff_threshold {pcc_out["diff_threshold"]};
  NumericVector individual_pccs = pcc_out["individual_pccs"];
  double obs_group_pcc {pcc_out["group_pcc"]};

  NumericVector rand_group_pccs(nreps);
  IntegerVector indiv_rand_pcc_geq_obs_pcc(dat.nrow());
  NumericVector individual_cvals(dat.nrow());
  std::mt19937_64 g;

  for (size_t i {}; i < nreps; i++) {
    Rcpp::checkUserInterrupt();
    NumericVector rand_indiv_pccs(dat.nrow());
    for (size_t j {}; j < dat.nrow(); j++) {
      NumericMatrix::Row current_row = dat(j,_);
      std::shuffle(current_row.begin(), current_row.end(), g);
      List rand_row_pcc = row_pcc(current_row, hypothesis, pairing_type, diff_threshold);
      double rand_indiv_pcc {rand_row_pcc["pcc"]};
      rand_indiv_pccs[j] = rand_indiv_pcc;
      if (rand_indiv_pccs[j] >= individual_pccs[j]) {
        indiv_rand_pcc_geq_obs_pcc[j] = indiv_rand_pcc_geq_obs_pcc[j] + 1;
      }
    }
    rand_group_pccs[i] = mean(rand_indiv_pccs);
  }
  for (size_t k {}; k < individual_cvals.length(); k++) {
    individual_cvals[k] = double(indiv_rand_pcc_geq_obs_pcc[k]) / double(nreps);
  }

  double group_cval = sum(rand_group_pccs >= obs_group_pcc) / double(nreps);

  return List::create(_["group_cval"] = group_cval, 
                      _["individual_cvals"] = individual_cvals,
                      _["rand_pccs"] = rand_group_pccs);
}
