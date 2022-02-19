# Generates pairwise ordinal relations from a vector, consisting of integers
# from the set {1, 0, -1}. When the pairing_type = "adjacent" option is used,
# calling ordering() on a vector of length N produces a vector of length N-1.
# When the pairing_type = "pairwise" option is used, calling ordering() on an
# N-length vector returns a vector of length ((N-1) * N)/2
# param: xs a numeric vector
# param: pairing_type a character string, either "adjacent" or "pairwise"
# param: diff_threshold: a numeric scalar
# return: a numeric vector
ordering <- function(xs, pairing_type, diff_threshold) {
  if (pairing_type == "pairwise") {
    c_sign_with_threshold(c_all_diffs(xs), diff_threshold)
  } else if (pairing_type == "adjacent") {
    c_sign_with_threshold(diff(xs), diff_threshold)
  }
}

# Removes elements of a hypothesis vector that correspond to the position of
# NAs in a numeric vector of data (a data row).
# param: xs a numeric vector
# param: h a numeric vector
# return: a numeric vector
conform <- function(xs, h) {
  h[-which(is.na(xs))]
}

#' Prints a summary of results from a fitted ordinal pattern analysis model.
#' @param x an object of class "opafit".
#' @param digits an integer used for rounding values in the output.
#' @examples
#' \dontrun{summary(opa_model)}
#' \dontrun{summary(opa_model, digits = 3)}
#' @export
summary.opafit <- function(x, ..., digits = 2L) {
  if (is.null(x$groups)) {
    cat("Ordinal Pattern Analysis of", ncol(x$data), "observations for",
        nrow(x$data), "individuals in 1 group \n\n")
  } else {
    cat("Ordinal Pattern Analysis of", ncol(x$data), "observations for",
        nrow(x$data), "individuals in", nlevels(x$groups), "groups \n\n")
  }
  cat("Group-level results:\n")
  print(group_results(x, digits))
  cat("\nIndividual-level results:\n")
  print(individual_results(x, digits))
  cat("\nPCCs were calculated for ", x$pairing_type,
      " ordinal relationships using a difference threshold of ", x$diff_threshold,
      ".\n", sep="")
  cat("Chance-values were calculated using the", x$cval_method, "method.\n")
}

#' @export
print.opafit <- function(x, ...) {
  print(x$call)
}

#' Plots individual PCCs relative to a user-supplied PCC threshold value.
#' @param m an object of class "opafit"
#' @param pcc_threshold a numeric scalar
#' @return an object of class "ggplot"
#' @examples
#' \dontrun{pcc_threshold_plot(opa_model)}
#' \dontrun{pcc_threshold_plot(opa_model, pcc_threshold = 85)}
#' @export
pcc_threshold_plot <- function(m, pcc_threshold = 75) {
  if (is.null(m$groups)) { # single group
    df <- data.frame(Individual = 1:nrow(m$data),
                     PCC = m$individual_pccs)
    ggplot2::ggplot(df, ggplot2::aes(x = Individual, y = PCC)) +
      ggplot2::scale_x_continuous(breaks = 1:length(m$individual_pccs)) +
      ggplot2::geom_hline(yintercept = pcc_threshold, linetype = 2, colour = "red") +
      ggplot2::geom_segment(ggplot2::aes(x=Individual, xend=Individual, y=0, yend=PCC), colour="black", size=0.3) +
      ggplot2::geom_point(size=2, shape=21, fill="royalblue") +
      ggplot2::guides(fill="none") +
      ggplot2::coord_flip() +
      ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                     panel.grid.minor.y = ggplot2::element_blank())
  } else { # multiple groups
    df <- data.frame(Individual = 1:length(m$individual_pccs),
                     group = factor(m$group_labels),
                     PCC = m$individual_pccs)
    ggplot2::ggplot(df, ggplot2::aes(x = Individual, y = PCC)) +
      ggplot2::scale_x_continuous(breaks = 1:length(m$individual_idx), labels=m$individual_idx) +
      ggplot2::geom_hline(yintercept = pcc_threshold, linetype = 2, colour = "red") +
      ggplot2::geom_segment(ggplot2::aes(x=Individual, xend=Individual, y=0, yend=PCC), colour="black", size=0.3) +
      ggplot2::geom_point(size=2, shape=21, ggplot2::aes(fill=group)) +
      ggplot2::coord_flip() +
      ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                     panel.grid.minor.y = ggplot2::element_blank(),
                     legend.position = "bottom")
  }
}

#' Plots individual-level PCCs and chance-values.
#' @param m an object of class "opafit" produced by \code{opa()}
#' @examples
#' \dontrun{plot(fitted_model)}
#' @export
plot.opafit <- function(m) {
  if (is.null(m$groups)) { # single group
    df <- data.frame(Individual = rep(1:nrow(m$data), 2),
                     stat = c(rep("PCCs", nrow(m$data)), rep("c-values", nrow(m$data))),
                     value = c(m$individual_pccs, m$individual_cvals))
    df$stat <- factor(df$stat, levels = c("PCCs", "c-values"))
    ggplot2::ggplot(df, ggplot2::aes(x = Individual, y = value)) +
      ggplot2::scale_x_continuous(breaks = 1:length(m$individual_pccs)) +
      ggplot2::geom_segment(ggplot2::aes(x=Individual, xend=Individual, y=0, yend=value), colour="black", size=0.3) +
      ggplot2::geom_point(size=2, shape=21, ggplot2::aes(fill=stat)) +
      ggplot2::facet_wrap(~ stat, nrow=1, scale="free") +
      ggplot2::ylab(NULL) +
      ggplot2::guides(fill="none") +
      ggplot2::coord_flip() +
      ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                     panel.grid.minor.y = ggplot2::element_blank())
  } else { # multiple groups
    df <- data.frame(Individual = rep(1:length(m$individual_pccs), 2),
                     group = rep(factor(m$group_labels), 2),
                     stat = c(rep("PCCs", nrow(m$data)), rep("c-values", nrow(m$data))),
                     value = c(m$individual_pccs, m$individual_cvals))
    df$stat <- factor(df$stat, levels = c("PCCs", "c-values"))
    ggplot2::ggplot(df, ggplot2::aes(x = Individual, y = value)) +
      ggplot2::scale_x_continuous(breaks = 1:length(m$individual_idx), labels=m$individual_idx) +
      ggplot2::geom_segment(ggplot2::aes(x=Individual, xend=Individual, y=0, yend=value), colour="black", size=0.3) +
      ggplot2::geom_point(size=2, shape=21, ggplot2::aes(fill=group)) +
      ggplot2::facet_wrap(~ stat, nrow=1, scale="free") +
      ggplot2::ylab(NULL) +
      ggplot2::coord_flip() +
      ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                     panel.grid.minor.y = ggplot2::element_blank(),
                     legend.position = "bottom")
  }
}

#' @export
group_results <- function(m, ...) {
  UseMethod("group_results")
}

#' @export
group_results.default <- function(m, ...) .NotYetImplemented()

#' Returns group-level PCC and chance values.
#'
#' @details
#' If the model was fitted with no grouping variable, a single PCC and c-value
#' are returned. If a grouping variable was specified in the call to \code{opa}
#' then PCCs and c-values are returned for each factor level of the grouping
#' variable.
#' @param m an object of class "opafit" produced by \code{opa()}.
#' @param digits a positive integer.
#' @examples
#' \dontrun{group_results(fitted_model)}
#' \dontrun{group_results(fitted_model, digits = 3)}
#' @export
group_results.opafit <- function(m, digits = 2) {
  if (is.null(m$groups)) {
    return(c(pcc = round(m$group_pcc, digits), cval = round(m$group_cval, digits)))
  }
  else {
    out <- cbind(round(m$group_pcc, digits), round(m$group_cval, digits))
    colnames(out) <- c("PCC", "cval")
    rownames(out) <- levels(m$groups)
    return(out)
  }
}

#' @export
individual_results <- function(m, ...) {
  UseMethod("individual_results")
}

#' @export
individual_results.default <- function(m, ...) .NotYetImplemented()

#' Returns individual-level PCC and chance values.
#'
#' @details
#' If the model was fitted with no grouping variable, a matrix of PCCs and
#' c-values are returned corresponding to the order of rows in the data. If the
#' \code{opa} model was fitted with a grouping variable specified, a table of
#' PCCs and c-values is returned ordered by factor level of the grouping
#' variable.
#' @param m an object of class "opafit" produced by \code{opa()}
#' @param digits an integer
#' @examples
#' \dontrun{individual_results(fitted_model)}
#' \dontrun{individual_results(fitted_model, digits = 3)}
#' @export
individual_results.opafit <- function(m, digits = 2) {
  if (is.null(m$groups)) {
    out <- round(cbind(m$individual_pccs, m$individual_cvals), digits)
    colnames(out) <- c("PCC", "cval")
    rownames(out) <- seq(length(m$individual_pccs))
    return(out)
  } else {
    out <- round(cbind(m$individual_idx, m$individual_pccs, m$individual_cvals), digits)
    colnames(out) <- c("Individual", "PCC", "cval")
    rownames(out) <- m$group_labels
    return(out)
  }
}

#' Convenience function for plotting a hypothesis.
#' @param h a numeric vector
#' @return an object of class "ggplot"
#' @examples
#' \dontrun{my_hypothesis <- c(1,2,3,3,3)
#' plot_hypothesis(my_hypothesis)}
#' @export
plot_hypothesis <- function(h) {
  df <- data.frame(condition = 1:length(h), hypothesis = h)
  ggplot2::ggplot(df, ggplot2::aes(x = condition, y = hypothesis)) +
    ggplot2::geom_point(size = 4, shape = 21, fill = "royalblue") +
    ggplot2::scale_x_continuous(labels = as.character(df$condition), breaks = df$condition) +
    ggplot2::scale_y_continuous(labels = as.character(df$hypothesis), breaks = df$hypothesis) +
    ggplot2::labs(x = "Condition", y = "Relative Value") +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
}

# Clean up C++ when package is unloaded.
.onUnload <- function(libpath) {
  library.dynam.unload("opa", libpath)
}
