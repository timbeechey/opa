# opa: An Implementation of Ordinal Pattern Analysis.
# Copyright (C) 2022 Timothy Beechey (tim.beechey@proton.me)
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

calc_cvalues <- function(pcc_out, nreps) {
  # vector to store each random group-level PCC
  rand_group_pccs <- numeric(nreps)
  # vector with 1 element for each individual to tally rand indiv pccs >= obs indiv pcc
  indiv_rand_pcc_geq_obs_pcc <- numeric(dim(pcc_out$data)[1])

  for (i in 1:nreps) {
    # within each rep, save all indiv rand pccs to use to calc rand group pcc
    rand_indiv_pccs <- numeric(dim(pcc_out$data)[1])
    for (j in 1:dim(pcc_out$data)[1]) { # iterate the data rows
      rand_row_pcc <- row_pcc(sample(pcc_out$data[j,]), pcc_out$hypothesis, pcc_out$pairing_type, pcc_out$diff_threshold)
      rand_indiv_pccs[j] <- rand_row_pcc$pcc
      if (rand_indiv_pccs[j] >= pcc_out$individual_pcc[j]) {
        indiv_rand_pcc_geq_obs_pcc[j] <- indiv_rand_pcc_geq_obs_pcc[j] + 1
      }
    }
    rand_group_pccs[i] <- mean(rand_indiv_pccs)
  }
  individual_cvals <- indiv_rand_pcc_geq_obs_pcc / nreps
  group_cval <- sum(rand_group_pccs >= pcc_out$group_pcc) / nreps

  return(list(group_cval = group_cval, individual_cvals = individual_cvals))
}
