row_pcc <- function(xs, h, pairing_type, diff_threshold) {
  # skip NAs in the data row
  xs_no_nas <- stats::na.omit(xs)
  # if there are NAs in the data row, skip corresponding
  # values in the hypothesis
  if (any(is.na(xs))) {
    hypothesis_no_nas <- conform(xs, h)
  } else {
    hypothesis_no_nas <- h
  }

  # get ordinal relations in hypothesis and data row
  hypothesis_ordering <- ordering(hypothesis_no_nas, pairing_type, 0)
  row_ordering <- ordering(stats::na.omit(xs), pairing_type, diff_threshold)

  # compare ordinal relations in hypothesis and data row
  match <- row_ordering == hypothesis_ordering

  n_pairs <- length(match)
  correct_pairs <- sum(match)
  pcc <- mean(match) * 100

  list(pcc = pcc,
       n_pairs = n_pairs,
       correct_pairs = correct_pairs)
}

pcc <- function(dat, h, pairing_type, diff_threshold) {

  individual_pccs <- numeric(nrow(dat))
  total_pairs <- 0
  correct_pairs <- 0

  for (r in 1:nrow(dat)) {
    result <- row_pcc(dat[r,], h, pairing_type, diff_threshold)
    individual_pccs[r] <- result$pcc
    total_pairs <- total_pairs + result$n_pairs
    correct_pairs <- correct_pairs + result$correct_pairs
  }

  group_pcc <- (correct_pairs / total_pairs) * 100

  list(group_pcc = group_pcc,
       individual_pccs = individual_pccs,
       total_pairs = total_pairs,
       correct_pairs = correct_pairs,
       data = dat,
       hypothesis = h,
       pairing_type = pairing_type,
       diff_threshold = diff_threshold)
}
