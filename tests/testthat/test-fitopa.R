test_dat <- data.frame(t1 = c(1, 3, 1, 1),
                       t2 = c(2, 2, 1, 2),
                       t3 = c(4, 1, 1, 1))

test_dat_all_wrong <- data.frame(t1 = c(3, 2, 1),
                                 t2 = c(3, 2, 1),
                                 t3 = c(3, 2, 1))

opamod1 <- opa(test_dat,
               1:3,
               pairing_type = "pairwise",
               cval_method = "exact")

opamod2 <- opa(test_dat,
               1:3,
               pairing_type = "adjacent",
               cval_method = "exact")

opamod3 <- opa(test_dat,
               1:3,
               pairing_type = "pairwise",
               cval_method = "exact",
               diff_threshold = 1)

opamod4 <- opa(test_dat_all_wrong,
               1:3,
               cval_method = "exact")

test_that("pairwise opa works", {
  expect_equal(opamod1$total_pairs, 12)
  expect_equal(opamod1$correct_pairs, 4)
  expect_equal(round(opamod1$group_pcc, 2), 33.33)
  #expect_equal(round(opamod1$group_cval, 2), 0.71)
  expect_equal(round(opamod1$individual_pccs, 2), c(100.00, 0.00, 0.00, 33.33))
  expect_equal(round(opamod1$individual_cvals, 2), c(0.17, 1.00, 1.00, 0.67))
})

test_that("adjacent opa works", {
  expect_equal(opamod2$total_pairs, 8)
  expect_equal(opamod2$correct_pairs, 3)
  expect_equal(round(opamod2$group_pcc, 2), 37.50)
  #expect_equal(round(opamod2$group_cval, 2), 0.71)
  expect_equal(round(opamod2$individual_pccs, 2), c(100.00, 0.00, 0.00, 50.00))
  expect_equal(round(opamod2$individual_cvals, 2), c(0.17, 1.00, 1.00, 0.67))
})

test_that("pairwise opa with diff_threshold works", {
  expect_equal(opamod3$total_pairs, 12)
  expect_equal(opamod3$correct_pairs, 2)
  expect_equal(round(opamod3$group_pcc, 2), 16.67)
  #expect_equal(round(opamod3$group_cval, 2), 0.83)
  expect_equal(round(opamod3$individual_pccs, 2), c(66.67, 0.00, 0.00, 0.00))
  expect_equal(round(opamod3$individual_cvals, 2), c(0.33, 1.00, 1.00, 1.00))
})

test_that("there aren't problems with 0% fits", {
  expect_equal(opamod4$total_pairs, 9)
  expect_equal(opamod4$correct_pairs, 0)
  expect_equal(round(opamod4$group_pcc, 2), 0.00)
  #expect_equal(round(opamod4$group_cval, 2), 1.00)
  expect_equal(round(opamod4$individual_pccs, 2), c(0.00, 0.00, 0.00))
  expect_equal(round(opamod4$individual_cvals, 2), c(1.00, 1.00, 1.00))
})
