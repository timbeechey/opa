# opa: An Implementation of Ordinal Pattern Analysis.
# Copyright (C) 2022 Timothy Beechey (tim.beechey@protonmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Calculate exact chance-values for percent correct classification values
# using a permutation test. This function generates every possible permutation
# of each data row
cval_exact <- function(pcc_out, progress) {
  individual_cvals <- numeric(dim(pcc_out$data)[1])
  individual_perm_pccs <- matrix(numeric(0),
                                 ncol=dim(pcc_out$data)[1],
                                 nrow=factorial(dim(pcc_out$data)[2]))
  total_perms <- 0
  total_perms_greater_eq <- 0
  # display a progress bar
  if (progress == TRUE) {
    progress_bar <- txtProgressBar(min = 0,
                                   max = dim(pcc_out$data)[1],
                                   initial = 0,
                                   width = 60,
                                   style = 3)
  }
  for (i in 1:dim(pcc_out$data)[1]) {
    if (any(is.na(unlist(pcc_out$data[i,])))) {
      hypothesis_no_nas <- conform(pcc_out$data[i,], pcc_out$hypothesis)
    } else {
      hypothesis_no_nas <- pcc_out$hypothesis
    }

    permutations <- c_generate_permutations(na.omit(pcc_out$data[i,]))
    n_perms <- dim(permutations)[2]
    total_perms <- total_perms + n_perms

    h_ordering <- c_ordering(hypothesis_no_nas,pcc_out$pairing_type,0)

    comp <- c_compare_perm_pccs(permutations, pcc_out, i, h_ordering)
    n_perms_greater_eq <- comp$n_perms_greater_eq
    individual_perm_pccs[1:length(comp$perm_pcc),i] <- comp$perm_pcc

    # Calculate the c-value of the data row
    individual_cvals[i] <- n_perms_greater_eq / n_perms
    # Increment the count of permutations with PCCs >= the observed PCC
    total_perms_greater_eq <- total_perms_greater_eq + n_perms_greater_eq
    if (progress == TRUE)
      setTxtProgressBar(progress_bar, i)
  }
  if (progress == TRUE)
    close(progress_bar)
  group_cval <- total_perms_greater_eq / total_perms

  return(list(individual_cvals = individual_cvals,
           group_cval = group_cval,
           pcc_replicates = individual_perm_pccs,
           total_perms = total_perms,
           perm_pccs_geq_obs_pcc = total_perms_greater_eq,
           observed_group_pcc = pcc_out$group_pcc))
}

cval_stochastic <- function(pcc_out, nreps, progress) {
  individual_cvals <- numeric(dim(pcc_out$data)[1])
  individual_perm_pccs <- matrix(numeric(0),
                                 ncol=dim(pcc_out$data)[1],
                                 nrow=nreps)
  total_perms_greater_eq <- 0

  # show a progress bar
  if (progress == TRUE) {
    progress_bar <- txtProgressBar(min = 0, max = dim(pcc_out$data)[1],
                                   initial = 0, width = 60, style = 3)
  }

  for (i in 1:dim(pcc_out$data)[1]) {
    if (any(is.na(unlist(pcc_out$data[i,])))) {
      hypothesis_no_nas <- conform(pcc_out$data[i,], pcc_out$hypothesis)
    } else {
      hypothesis_no_nas <- pcc_out$hypothesis
    }

    permutations <- c_random_shuffles(nreps, na.omit(pcc_out$data[i,]))

    h_ordering <- c_ordering(hypothesis_no_nas, pcc_out$pairing_type, 0)

    comp <- c_compare_perm_pccs(permutations, pcc_out, i, h_ordering)
    n_perms_greater_eq <- comp$n_perms_greater_eq
    individual_perm_pccs[,i] <- comp$perm_pcc

    # Calculate the c-value of the data row
    individual_cvals[i] <- n_perms_greater_eq / nreps
    # Increment the count of permutations with PCCs >= the observed PCC
    total_perms_greater_eq <- total_perms_greater_eq + n_perms_greater_eq

    if (progress == TRUE)
      setTxtProgressBar(progress_bar, i)
  }
  if (progress == TRUE)
    close(progress_bar)

  group_cval <- total_perms_greater_eq / (nreps * dim(pcc_out$data)[1])

  return(list(individual_cvals = individual_cvals,
            group_cval = group_cval,
            pcc_replicates = individual_perm_pccs,
            total_perms = nreps * dim(pcc_out$data)[1],
            perm_pccs_geq_obs_pcc = total_perms_greater_eq,
            observed_group_pcc = pcc_out$group_pcc))
}
