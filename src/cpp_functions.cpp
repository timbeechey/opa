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

#include <RcppArmadillo.h>
#include <RcppArmadilloExtensions/sample.h>
using namespace Rcpp;
// [[Rcpp::depends(RcppArmadillo)]]

// Skip elements in a hypothesis vector that correspond to NA values in the
// data vector. This function is called when the data vector contains at least
// one NA value.
// @param xs, a numeric vector
// @param h, a numeric vector.
// @return a numeric vector
// [[Rcpp::export]]
arma::vec conform(arma::rowvec xs, arma::vec h) {
    return h.elem(arma::find_finite(xs));
}
    

// Returns the sign of every element of a vector conditional on a
// user-supplied difference threshold diff_threshold.
// Returns 1 for any positive input value larger than diff_threshold.
// Returns -1 for any negative input value smaller than -diff_threshold.
// Returns 0 for any input value that is both smaller than diff_threshold
// and larger than -diff_threshold. This function is equivalent to R's
// built-in sign() function when diff_threshold = 0.
// @param xs, a numeric vector.
// @param diff_threshold, a double.
// @return an int from the set {1, 0, -1}.
// [[Rcpp::export]]
arma::vec sign_with_threshold(arma::vec xs, double diff_threshold) {
    arma::vec sign_vector(xs.n_elem);
    for (size_t i {}; i < xs.n_elem; i++) {
        if (std::isnan(xs[i])) {
            sign_vector[i] = arma::datum::nan;
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
// @param xs, a numeric vector.
// @return a numeric vector.
// [[Rcpp::export]]
arma::vec all_diffs(arma::vec xs) {
    size_t count {};
    // Calculate the length of the vector as the Nth-1 triangular number
    auto n_pairs {((xs.n_elem - 1) * xs.n_elem) / 2};
    arma::vec diffs(n_pairs);
    // Fill the diffs vector with the difference between each pair of vector elements
    for (size_t i {}; i < xs.n_elem; i++) {
        for (size_t j {i+1}; j < xs.n_elem; j++) {
            diffs(count) = xs(j) - xs(i);
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
// @param xs, a numeric vector.
// @param pairing_type, a string, either "adjacent" or "pairwise".
// @param diff_threshold, a positive double.
// @return an IntegerVector.
// [[Rcpp::export]]
arma::vec ordering(arma::vec xs, std::string pairing_type, double diff_threshold) {
    if (pairing_type == "pairwise") {
        return(sign_with_threshold(all_diffs(xs), diff_threshold));   
    } else{
        return(sign_with_threshold(arma::diff(xs), diff_threshold));
    }
}


// Calculate the percentage of correct classifications for a single row of data.
// @param xs, a numeric vector.
// @param h, a numeric vector.
// @param pairing_type, a string, either "adjacent" or "pairwise".
// @param diff_threshold, a non-negative double.
// @return an Rcpp::List
// [[Rcpp::export]]
Rcpp::List row_pcc(arma::rowvec xs, arma::vec h, std::string pairing_type, double diff_threshold) {
    arma::vec hypothesis_no_nas = xs.has_nan() ? conform(xs, h) : h;
    arma::vec hypothesis_ordering = ordering(hypothesis_no_nas, pairing_type, 0);
    arma::vec row_ordering = ordering(xs.elem(arma::find_finite(xs)), pairing_type, diff_threshold);
    arma::vec match(row_ordering.n_elem);
    for (size_t i{}; i < row_ordering.n_elem; i++) {
        match(i) = row_ordering(i) == hypothesis_ordering(i);
    }
    auto n_pairs {match.n_elem};
    auto correct_pairs {arma::accu(match)};
    auto pcc {(correct_pairs/n_pairs) * 100};
    return Rcpp::List::create(_["n_pairs"] = n_pairs,
                              _["correct_pairs"] = correct_pairs,
                              _["pcc"] = pcc);
}


// Calculate the percentage of correct classifications for each row of data,
// and the PCC of the group as a whole.
// @param dat, a numeric matrix.
// @param h, a numeric vector.
// @param pairing_type, a string, either "adjacent" or "pairwise".
// @param diff_threshold, a non-negative double.
// @return an Rcpp::List.
// [[Rcpp::export]]
Rcpp::List pcc(arma::mat dat, arma::vec h, std::string pairing_type, double diff_threshold) {
    arma::vec individual_pccs(dat.n_rows);
    size_t total_pairs {};
    size_t correct_pairs {};
    
    for (int r{}; r < dat.n_rows; r++) {
        Rcpp::List result = row_pcc(dat.row(r), h, pairing_type, diff_threshold);
        size_t result_n_pairs {result["n_pairs"]};
        size_t result_correct_pairs {result["correct_pairs"]};
        
        individual_pccs(r) = result["pcc"];
        total_pairs += result_n_pairs;
        correct_pairs += result_correct_pairs;
    }
    
    auto group_pcc {(correct_pairs / (double)total_pairs) * 100};
    
    return Rcpp::List::create(_["group_pcc"] = group_pcc,
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
// @param pcc_out, an Rcpp::List.
// @param nreps, an integer.
// @return an Rcpp::List.
// [[Rcpp::export]]
Rcpp::List calc_cvalues(Rcpp::List pcc_out, int nreps) {
    arma::mat dat = pcc_out["data"];
    arma::vec hypothesis = pcc_out["hypothesis"];
    std::string pairing_type {pcc_out["pairing_type"]};
    auto diff_threshold {pcc_out["diff_threshold"]};
    arma::vec individual_pccs = pcc_out["individual_pccs"];
    auto obs_group_pcc {pcc_out["group_pcc"]};
    
    arma::vec rand_group_pccs(nreps);
    arma::vec indiv_rand_pcc_geq_obs_pcc(dat.n_rows);
    arma::vec individual_cvals(dat.n_rows);
    
    for (size_t i {}; i < nreps; i++) {
        Rcpp::checkUserInterrupt();
        arma::vec rand_indiv_pccs(dat.n_rows);
        for (size_t j {}; j < dat.n_rows; j++) {
            arma::rowvec current_row = dat.row(j);
            arma::rowvec rand_row = arma::shuffle(current_row);
            List rand_row_pcc = row_pcc(rand_row, hypothesis, pairing_type, diff_threshold);
            auto rand_indiv_pcc {rand_row_pcc["pcc"]};
            rand_indiv_pccs[j] = rand_indiv_pcc;
            if (rand_indiv_pccs[j] >= individual_pccs[j]) {
                indiv_rand_pcc_geq_obs_pcc[j] = indiv_rand_pcc_geq_obs_pcc[j] + 1;
            }
        }
        rand_group_pccs[i] = mean(rand_indiv_pccs);
    }
    for (size_t k {}; k < individual_cvals.n_elem; k++) {
        individual_cvals[k] = double(indiv_rand_pcc_geq_obs_pcc[k]) / double(nreps);
    }
    
    auto group_cval = sum(rand_group_pccs >= obs_group_pcc) / double(nreps);
    
    return List::create(_["group_cval"] = group_cval, 
                        _["individual_cvals"] = individual_cvals,
                        _["rand_pccs"] = rand_group_pccs);
}
