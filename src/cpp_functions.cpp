// opa: An Implementation of Ordinal Pattern Analysis.
// Copyright (C) 2024 Timothy Beechey (tim.beechey@proton.me)

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
// [[Rcpp::depends(RcppArmadillo)]]

// Skip elements in a hypothesis vector that correspond to NA values in the
// data vector.
// @param xs, an arma::rowvec
// @param h, an arma::vec
// @return an arma::vec
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
// @param xs, an arma::vec
// @param diff_threshold, a double
// @return an int from the set {1, 0, -1}
// [[Rcpp::export]]
arma::vec sign_with_threshold(arma::vec xs, double diff_threshold) {
    size_t n {xs.n_elem};
    arma::vec sign_vector {arma::zeros(n)};
    for (size_t i {0}; i < n; i++) {
        if (xs[i] > diff_threshold) {
            sign_vector[i] = 1;
        } else if (xs[i] < -diff_threshold) {
            sign_vector[i] = -1;
        }
    }
    return sign_vector;
}


// Calculate a triangular number.
// @param n a size_t
// @return a size_t
// [[Rcpp::export]]
size_t triangular(size_t n) {
    size_t tn {(n * (n + 1)) / 2};
    return tn;
}


// Calculate the difference between every pair of elements in a vector.
// This function is called when the pairing_type = "pairwise" option is used.
// For an input vector of length N, the output vector has length equal to the 
// Nth-1 triangular number, calculated as (N-1 * N) / 2.
// @param xs, an arma::vec
// @return an arma::vec
// [[Rcpp::export]]
arma::vec all_diffs(arma::vec xs) {
    size_t count {0};
    size_t n {xs.n_elem};
    // Set the length of the vector as the Nth-1 triangular number
    arma::vec diffs(triangular(n - 1));
    // Fill the diffs vector with the difference between each pair of vector elements
    for (size_t i {0}; i < n; i++) {
        for (size_t j {i + 1}; j < n; j++) {
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
// @param xs, an arma::vec
// @param pairing_type, a string, either "adjacent" or "pairwise"
// @param diff_threshold, a double, always non-negative
// @return an arma::vec
// [[Rcpp::export]]
arma::vec ordering(arma::vec xs, std::string pairing_type, double diff_threshold) {
    if (pairing_type == "pairwise") {
        return(sign_with_threshold(all_diffs(xs), diff_threshold));
    } else{
        return sign_with_threshold(arma::diff(xs), diff_threshold);
    }
}


// Calculate the percentage of correct classifications for a single row of data.
// @param xs, an arma::rowvec
// @param h, an arma::vec
// @param pairing_type, a string, either "adjacent" or "pairwise"
// @param diff_threshold, a double, always non-negative
// @return an Rcpp::List
// [[Rcpp::export]]
Rcpp::List row_pcc(arma::rowvec xs, arma::vec h, std::string pairing_type, double diff_threshold) {
    arma::vec hypothesis_no_nas = xs.has_nan() ? conform(xs, h) : h;
    arma::vec hypothesis_ordering = ordering(hypothesis_no_nas, pairing_type, 0);
    arma::vec row_ordering = ordering(xs.elem(arma::find_finite(xs)), pairing_type, diff_threshold);
    arma::vec match(row_ordering.n_elem);
    for (size_t i {0}; i < row_ordering.n_elem; i++) {
        match(i) = row_ordering(i) == hypothesis_ordering(i);
    }
    auto n_pairs {match.n_elem};
    auto correct_pairs {arma::accu(match)}; // accu() is armadillo's sum()
    auto pcc {(correct_pairs/n_pairs) * 100};
    return Rcpp::List::create(Rcpp::Named("n_pairs") = n_pairs,
                              Rcpp::Named("correct_pairs") = correct_pairs,
                              Rcpp::Named("pcc") = pcc);
}

// Calculate the percentage of correct classifications for a single row of data.
// This function returns only the scalar PCC value for use in c-value calculation.
// @param xs, an arma::rowvec
// @param h, an arma::vec
// @param pairing_type, a string, either "adjacent" or "pairwise"
// @param diff_threshold, a double, always non-negative
// @return a double
// [[Rcpp::export]]
double scalar_row_pcc(arma::rowvec xs, arma::vec h, std::string pairing_type, double diff_threshold) {
    arma::vec hypothesis_no_nas = xs.has_nan() ? conform(xs, h) : h;
    arma::vec hypothesis_ordering = ordering(hypothesis_no_nas, pairing_type, 0);
    arma::vec row_ordering = ordering(xs.elem(arma::find_finite(xs)), pairing_type, diff_threshold);
    arma::vec match(row_ordering.n_elem);
    for (size_t i {0}; i < row_ordering.n_elem; i++) {
        match(i) = row_ordering(i) == hypothesis_ordering(i);
    }
    auto n_pairs {match.n_elem};
    auto correct_pairs {arma::accu(match)};
    auto pcc {(correct_pairs/n_pairs) * 100};
    return pcc;
}


// Calculate the percentage of correct classifications for each row of data,
// and the PCC of the group as a whole.
// @param dat, an arma::mat
// @param h, an arma::vec
// @param pairing_type, a string, either "adjacent" or "pairwise"
// @param diff_threshold, a double, always non-negative
// @return an Rcpp::List
// [[Rcpp::export]]
Rcpp::List pcc(arma::mat dat, arma::vec h, std::string pairing_type, double diff_threshold) {
    arma::vec individual_pccs(dat.n_rows);
    size_t total_pairs {0};
    size_t correct_pairs {0};
    
    for (size_t r {0}; r < dat.n_rows; r++) {
        Rcpp::List result = row_pcc(dat.row(r), h, pairing_type, diff_threshold);
        size_t result_n_pairs {result["n_pairs"]};
        size_t result_correct_pairs {result["correct_pairs"]};
        
        individual_pccs(r) = result["pcc"];
        total_pairs += result_n_pairs;
        correct_pairs += result_correct_pairs;
    }
    
    auto group_pcc {(correct_pairs / (double)total_pairs) * 100};
    
    return Rcpp::List::create(Rcpp::Named("group_pcc") = group_pcc,
                              Rcpp::Named("individual_pccs") = individual_pccs,
                              Rcpp::Named("total_pairs") = total_pairs,
                              Rcpp::Named("correct_pairs") = correct_pairs,
                              Rcpp::Named("data") = dat,
                              Rcpp::Named("hypothesis") = h,
                              Rcpp::Named("pairing_type") = pairing_type,
                              Rcpp::Named("diff_threshold") = diff_threshold);
}


// Shuffle each column of a matrix separately and return
// a copy of the resulting shuffled matrix.
// @param x, an arma::mat
// @return an arma::mat
arma::mat shuffle_each_column(arma::mat x) {
    for (size_t i {0}; i < x.n_cols; i++) {
        x.col(i) = arma::shuffle(x.col(i));
    }
    return x;
}


// Calculate the chance value for each individual in a matrix of data, and
// the chance value for the group as a whole.
// @param pcc_out, an Rcpp::List
// @param nreps, an int
// @param shuufle_across_individuals, a bool
// @return an Rcpp::List
// [[Rcpp::export]]
Rcpp::List calc_cvalues(Rcpp::List pcc_out, int nreps, bool shuffle_across_individuals) {
    arma::mat dat = pcc_out["data"];
    arma::vec hypothesis = pcc_out["hypothesis"];
    Rcpp::String pairing_type {pcc_out["pairing_type"]};
    auto diff_threshold {pcc_out["diff_threshold"]};
    arma::vec individual_pccs = pcc_out["individual_pccs"];
    auto obs_group_pcc {pcc_out["group_pcc"]};
    auto num_rows {dat.n_rows};
    auto num_cols {dat.n_cols};
    
    arma::vec rand_group_pccs(nreps);
    arma::vec indiv_rand_pcc_geq_obs_pcc(num_rows);
    arma::vec individual_cvals(num_rows);
    arma::mat shuffled_dat_cols(num_rows, num_cols);
    
    for (size_t i {0}; i < nreps; i++) {
        Rcpp::checkUserInterrupt();
        arma::vec rand_indiv_pccs(num_rows);
        double rand_indiv_pcc {0.0};

        if (shuffle_across_individuals) {
            shuffled_dat_cols = shuffle_each_column(dat);
        }

        for (size_t j {0}; j < num_rows; j++) {
            if (shuffle_across_individuals) {
                rand_indiv_pcc = scalar_row_pcc(arma::shuffle(shuffled_dat_cols.row(j)), hypothesis, pairing_type, diff_threshold);
            } else {
                rand_indiv_pcc = scalar_row_pcc(arma::shuffle(dat.row(j)), hypothesis, pairing_type, diff_threshold);
            }
            rand_indiv_pccs(j) = rand_indiv_pcc;
            if (rand_indiv_pccs(j) >= individual_pccs[j]) {
                indiv_rand_pcc_geq_obs_pcc[j] += 1;
            }
        }
        rand_group_pccs[i] = arma::mean(rand_indiv_pccs);
    }
    for (size_t k {0}; k < individual_cvals.n_elem; k++) {
        individual_cvals[k] = indiv_rand_pcc_geq_obs_pcc[k] / double(nreps);
    }
    
    auto group_cval = arma::accu(rand_group_pccs >= obs_group_pcc) / double(nreps);
    
    return Rcpp::List::create(Rcpp::Named("group_cval") = group_cval,
                              Rcpp::Named("individual_cvals") = individual_cvals,
                              Rcpp::Named("rand_pccs") = rand_group_pccs);
}
