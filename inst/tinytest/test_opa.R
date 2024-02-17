# Tests of results that are computed based on random number generation
# are only run locally as even with a seed the results are slightly 
# different on different machines

set.seed(22)

test_dat <- data.frame(group = c("a", "b", "a", "b"),
                       t1 = c(1, 3, 1, 1),
                       t2 = c(2, 2, 1, 2),
                       t3 = c(4, 1, 1, 1))
test_dat$group <- factor(test_dat$group, levels = c("a", "b"))

test_dat_all_wrong <- data.frame(t1 = c(3, 2, 1),
                                 t2 = c(3, 2, 1),
                                 t3 = c(3, 2, 1))

h1 <- hypothesis(1:3)

opamod1 <- opa(test_dat[,2:4],
               h1,
               pairing_type = "pairwise")

opamod1a <- opa(test_dat[,2:4],
               c(3, 1, 2),
               pairing_type = "pairwise")

opamod2 <- opa(test_dat[,2:4],
               1:3,
               pairing_type = "adjacent")

opamod3 <- opa(test_dat[,2:4],
               1:3,
               pairing_type = "pairwise",
               diff_threshold = 1)

opamod4 <- opa(test_dat_all_wrong,
               1:3)

opamod5 <- opa(test_dat[,2:4],
               1:3,
               group = test_dat$group,
               pairing_type = "pairwise")

pw1 <- compare_conditions(opamod1)

# compare group PCCs from 2 different hypotheses
ch1 <- compare_hypotheses(opamod1, opamod1a)
# compare model to itself to produce PCC=0, cval=1
ch2 <- compare_hypotheses(opamod1, opamod1)

# compare subgroup pccs
group_comp <- compare_groups(opamod5, "a", "b")

# check types
expect_inherits(h1, "opahypothesis")
expect_inherits(opamod1, "opafit")
expect_inherits(pw1, "pairwiseopafit")
expect_inherits(group_comp, "opaGroupComparison")
expect_inherits(ch1, "opaHypothesisComparison")
expect_inherits(random_pccs(opamod1), "oparandpccs")

# check getters
expect_equal(correct_pairs(opamod1), 4)
expect_equal(incorrect_pairs(opamod1), 8)
expect_equal(round(group_pccs(opamod1), 2), 33.33)
expect_true(group_cvals(opamod1) > 0.4)
expect_true(group_cvals(opamod1) < 0.8)
expect_equal(round(individual_pccs(opamod1), 2), c(100.00, 0.00, 0.00, 33.33))
expect_equal(round(group_results(opamod1)[1], 2), 33.33)
expect_equal(length(random_pccs(opamod1)), opamod1$nreps)

# check functions that produce side-effects
expect_stdout(print(opamod1))
expect_stdout(summary(opamod1))
expect_stdout(plot(opamod1))
expect_stdout(print(h1))
expect_stdout(summary(h1))
expect_stdout(plot(h1))
expect_stdout(print(pw1))
expect_stdout(print(ch1))
expect_stdout(summary(ch1))
expect_stdout(print(group_comp))
expect_stdout(summary(group_comp))
expect_stdout(print(group_results(opamod1)))
expect_stdout(print(individual_results(opamod1)))

#========== test pairwise opa works ==========
expect_equal(opamod1$total_pairs, 12)
expect_equal(opamod1$correct_pairs, 4)
expect_equal(round(opamod1$group_pcc, 2), 33.33)
expect_equal(round(opamod1$individual_pccs, 2), matrix(c(100.00, 0.00, 0.00, 33.33)))

#========== check adjacent opa works ==========
expect_equal(opamod2$total_pairs, 8)
expect_equal(opamod2$correct_pairs, 3)
expect_equal(round(opamod2$group_pcc, 2), 37.50)
expect_equal(round(opamod2$individual_pccs, 2), matrix(c(100.00, 0.00, 0.00, 50.00)))

#========== check pairwise opa with diff_threshold works ==========
expect_equal(opamod3$total_pairs, 12)
expect_equal(opamod3$correct_pairs, 2)
expect_equal(round(opamod3$group_pcc, 2), 16.67)
expect_equal(round(opamod3$individual_pccs, 2), matrix(c(66.67, 0.00, 0.00, 0.00)))

#========== check there aren't problems with 0% fits ==========
expect_equal(opamod4$total_pairs, 9)
expect_equal(opamod4$correct_pairs, 0)
expect_equal(round(opamod4$group_pcc, 2), 0.00)
expect_equal(round(opamod4$group_cval, 2), 1.00)
expect_equal(round(opamod4$individual_pccs, 2), matrix(c(0.00, 0.00, 0.00)))
expect_equal(round(opamod4$individual_cvals, 2), matrix(c(1.00, 1.00, 1.00)))

#========== check pairwise comparisons work ==========
expect_equal(round(pw1$pccs_mat[2,1], 3), 50)
expect_equal(round(pw1$pccs_mat[3,1], 3), 25)
expect_equal(round(pw1$pccs_mat[3,2], 3), 25)

#========== check hypothesis comparisons work ==========
expect_equal(round(ch2$pcc_diff, 2), 0)
expect_equal(round(ch2$cval, 2), 1)

#========== check that missing values are handled correctly ==========
expect_equal(opa:::conform(c(NA, 2, 3, 4), c(1, 2, 3, 4)), matrix(c(2, 3, 4)))
expect_equal(opa:::conform(c(1, NA, 3, 4), c(1, 2, 3, 4)), matrix(c(1, 3, 4)))
expect_equal(opa:::conform(c(1, 2, NA, 4), c(1, 2, 3, 4)), matrix(c(1, 2, 4)))
expect_equal(opa:::conform(c(1, 2, 3, NA), c(1, 2, 3, 4)), matrix(c(1, 2, 3)))
expect_equal(opa:::conform(c(1, 2, 3, 4), c(1, 2, 3, 4)), matrix(c(1, 2, 3, 4)))
expect_equal(opa:::conform(c(NA, NA, 3, 4), c(1, 2, 3, 4)), matrix(c(3, 4)))
expect_equal(opa:::conform(c(NA, 2, NA, NA), c(1, 2, 3, 4)), matrix(c(2)))

#========== check that ordering() works ==========
expect_equal(opa:::ordering(c(1, 2, 3, 4), "pairwise", 0), matrix(c(1, 1, 1, 1, 1, 1)))
expect_equal(opa:::ordering(c(1, 2, 3, 4), "pairwise", 1), matrix(c(0, 1, 1, 0, 1, 0)))
expect_equal(opa:::ordering(c(4.3, 2.1, 3.5, 1.7), "pairwise", 0), matrix(c(-1, -1, -1, 1, -1, -1)))
expect_equal(opa:::ordering(c(4.3, 2.1, 3.5, 1.7), "pairwise", 1), matrix(c(-1, 0, -1, 1, 0, -1)))
expect_equal(opa:::ordering(c(1, 2, 3, 4), "adjacent", 0), matrix(c(1, 1, 1)))
expect_equal(opa:::ordering(c(1, 2, 3, 4), "adjacent", 1), matrix(c(0, 0, 0)))
expect_equal(opa:::ordering(c(4.3, 2.1, 3.5, 1.7), "adjacent", 0), matrix(c(-1, 1, -1)))
expect_equal(opa:::ordering(c(4.3, 2.1, 3.5, 1.7), "adjacent", 1), matrix(c(-1, 1, -1)))

expect_equal(opa:::sign_with_threshold(3, 0), matrix(1))
expect_equal(opa:::sign_with_threshold(-2, 0), matrix(-1))
expect_equal(opa:::sign_with_threshold(3, 1), matrix(1))
expect_equal(opa:::sign_with_threshold(-2, 1), matrix(-1))
expect_equal(opa:::sign_with_threshold(0.3, 1), matrix(0))
expect_equal(opa:::sign_with_threshold(-0.2, 1), matrix(0))

expect_equal(opa:::all_diffs(c(1, 2, 3, 4)), matrix(c(1, 2, 3, 1, 2, 1)))

expect_equal(opa:::row_pcc(c(2, 4, 6, 8), c(1, 2, 3, 4), "pairwise", 0), list(n_pairs = 6, correct_pairs = 6, pcc = 100.0))
expect_equal(opa:::row_pcc(c(2, 1, 6, 8), c(1, 2, 3, 4), "pairwise", 0), list(n_pairs = 6, correct_pairs = 5, pcc = (5/6)*100))
expect_equal(opa:::row_pcc(c(2, 4, 6, 8), c(1, 2, 3, 4), "adjacent", 0), list(n_pairs = 3, correct_pairs = 3, pcc = 100.0))
expect_equal(opa:::row_pcc(c(2, 1, 6, 8), c(1, 2, 3, 4), "adjacent", 0), list(n_pairs = 3, correct_pairs = 2, pcc = (2/3)*100))

# Run these tests locally only

# #========== test pairwise opa works ==========
# expect_equal(round(opamod1$group_cval, 2), 0.63)
# expect_equal(round(opamod1$individual_cvals, 2), matrix(c(0.17, 1.00, 1.00, 0.67)))

# #========== check adjacent opa works ==========
# expect_equal(round(opamod2$group_cval, 2), 0.6)
# expect_equal(round(opamod2$individual_cvals, 2), c(0.17, 1.00, 1.00, 0.67))

# #========== check pairwise opa with diff_threshold works ==========
# expect_equal(round(opamod3$group_cval, 2), 0.5)
# expect_equal(round(opamod3$individual_cvals, 2), c(0.34, 1.00, 1.00, 1.00))

# #========== check pairwise comparisons work ==========
# expect_equal(round(pw1$cvals_mat[2,1], 3), 0.513)
# expect_equal(round(pw1$cvals_mat[3,1], 3), 0.769)
# expect_equal(round(pw1$cvals_mat[3,2], 3), 0.898)

# #========== check hypothesis comparisons work ==========
# expect_equal(round(ch1$pcc_diff, 2), 8.33)
# expect_equal(round(ch1$cval, 2), 0.93)

# #========== check subgroup comparisons work ==========
# expect_equal(round(group_comp$pcc_diff, 2), 33.33)
# expect_equal(round(group_comp$cval, 2), 0.42)
