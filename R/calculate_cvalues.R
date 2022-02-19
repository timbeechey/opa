compare_perm_pccs <- function(perms_list, m, indiv_idx, H_ord) {
  perm_pcc <- numeric(length(perms_list))
  n_perms_greater_eq <- 0
  for (i in 1:length(perms_list)) {
    perm_pcc[i] <- mean(ordering(unlist(perms_list[i]),
                                 m$pairing_type,
                                 m$diff_threshold) == H_ord) * 100
    if (perm_pcc[i] >= m$individual_pccs[indiv_idx])
      n_perms_greater_eq <- n_perms_greater_eq + 1
  }
  list(n_perms_greater_eq = n_perms_greater_eq,
       perm_pcc = perm_pcc)
}

# Calculate exact chance-values for percent correct classification values
# using a permutation test. This function generates every possible permutation
# of each data row
cval_exact <- function(pcc_out) {
  individual_cvals <- numeric(nrow(pcc_out$data))
  individual_perm_pccs <- matrix(numeric(0),
                                 ncol=nrow(pcc_out$data),
                                 nrow=factorial(ncol(pcc_out$data)))
  total_perms <- 0
  total_perms_greater_eq <- 0
  progress_bar <- txtProgressBar(min = 0,
                                 max = nrow(pcc_out$data),
                                 initial = 0,
                                 width = 60,
                                 style = 3)
  for (i in 1:nrow(pcc_out$data)) {
    if (any(is.na(unlist(pcc_out$data[i,])))) {
      hypothesis_no_nas <- conform(pcc_out$data[i,], pcc_out$hypothesis)
    } else {
      hypothesis_no_nas <- pcc_out$hypothesis
    }

    permutations <- combinat::permn(na.omit(pcc_out$data[i,]))
    n_perms <- length(permutations)
    total_perms <- total_perms + n_perms

    h_ordering <- ordering(hypothesis_no_nas,pcc_out$pairing_type,0)

    comp <- compare_perm_pccs(permutations, pcc_out, i, h_ordering)
    n_perms_greater_eq <- comp$n_perms_greater_eq
    individual_perm_pccs[1:length(comp$perm_pcc),i] <- comp$perm_pcc

    # Calculate the c-value of the data row
    individual_cvals[i] <- n_perms_greater_eq / n_perms
    # Increment the count of permutations with PCCs >= the observed PCC
    total_perms_greater_eq <- total_perms_greater_eq + n_perms_greater_eq
    setTxtProgressBar(progress_bar, i)
  }
  close(progress_bar)
  group_cval <- total_perms_greater_eq / total_perms

  return(list(individual_cvals = individual_cvals,
         group_cval = group_cval,
         pcc_replicates = individual_perm_pccs,
         total_perms = total_perms,
         perm_pccs_geq_obs_pcc = total_perms_greater_eq,
         observed_group_pcc = pcc_out$group_pcc))
}

cval_stochastic <- function(pcc_out, nreps) {
  individual_cvals <- numeric(nrow(pcc_out$data))
  individual_perm_pccs <- matrix(numeric(0),
                                 ncol=nrow(pcc_out$data),
                                 nrow=nreps)
  total_perms_greater_eq <- 0
  progress_bar <- txtProgressBar(min = 0, max = nrow(pcc_out$data),
                                 initial = 0, width = 60, style = 3)
  for (i in 1:nrow(pcc_out$data)) {
    if (any(is.na(unlist(pcc_out$data[i,])))) {
      hypothesis_no_nas <- conform(pcc_out$data[i,], pcc_out$hypothesis)
    } else {
      hypothesis_no_nas <- pcc_out$hypothesis
    }

    permutations <- replicate(nreps,
                              sample(na.omit(pcc_out$data[i,])),
                              simplify = FALSE)

    h_ordering <- ordering(hypothesis_no_nas, pcc_out$pairing_type, 0)

    comp <- compare_perm_pccs(permutations, pcc_out, i, h_ordering)
    n_perms_greater_eq <- comp$n_perms_greater_eq
    individual_perm_pccs[,i] <- comp$perm_pcc

    # Calculate the c-value of the data row
    individual_cvals[i] <- n_perms_greater_eq / nreps
    # Increment the count of permutations with PCCs >= the observed PCC
    total_perms_greater_eq <- total_perms_greater_eq + n_perms_greater_eq
    setTxtProgressBar(progress_bar, i)
  }
  close(progress_bar)
  group_cval <- total_perms_greater_eq / (nreps * nrow(pcc_out$data))

  return(list(individual_cvals = individual_cvals,
         group_cval = group_cval,
         pcc_replicates = individual_perm_pccs,
         total_perms = nreps * nrow(pcc_out$data),
         perm_pccs_geq_obs_pcc = total_perms_greater_eq,
         observed_group_pcc = pcc_out$group_pcc))
}
