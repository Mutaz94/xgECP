#' Plot data with mean and confidence intervals
#'
#' \code{xgx_stat_ci} returns a ggplot layer plotting mean +/- confidence 
#' intervals
#' 
#' This function can be used to generate mean +/- confidence interval plots 
#' for different distributions, 
#' and multiple geoms with a single function call.
#'
#' @param mapping Set of aesthetic mappings created by `aes` or `aes_`. 
#' If specified and `inherit.aes = TRUE` (the default), it is combined with the 
#' default mapping at the top level of the plot. You must supply mapping if 
#' there is no plot mapping.
#' @param data The data to be displayed in this layer. There are three options:
#' 
#' If NULL, the default, the data is inherited from the plot data as specified 
#' in the call to ggplot.
#' 
#' A data.frame, or other object, will override the plot data. All objects 
#' will be fortified to produce a data frame. See fortify for which variables 
#' will be created.
#' 
#' A function will be called with a single argument, the plot data. The return 
#' value must be a data.frame., and will be used as the layer data.
#' @param conf_level The percentile for the confidence interval (should fall 
#' between 0 and 1). The default is 0.95, which corresponds to a 95 percent 
#' confidence interval.
#' @param distribution The distribution which the data follow, used for 
#' calculating confidence intervals. The options are "normal", "lognormal", 
#' and "binomial". The "normal" option will use the Student t Distribution 
#' to calculate confidence intervals, the "lognormal" option will transform 
#' data to the log space first. The "binomial" option will use the
#' \code{\link[binom:binom.confint]{binom.exact}} function to calculate the
#' confidence 
#' intervals. Note: binomial data must be numeric and contain only 1's and 0's. 
#' @param geom Use to override the default geom. Can be a list of multiple 
#' geoms, e.g. list("point","line","errorbar"), which is the default.
#' @param position Position adjustment, either as a string, or the result of 
#' a call to a position adjustment function.
#' @param fun.args Optional additional arguments passed on to the functions.
#' @param na.rm If FALSE, the default, missing values are removed with a 
#' warning. If TRUE, missing values are silently removed.
#' @param show.legend logical. Should this layer be included in the legends? 
#' NA, the default, includes if any aesthetics are mapped. FALSE never 
#' includes, and TRUE always includes.
#' @param inherit.aes If FALSE, overrides the default aesthetics, rather 
#' than combining with them. This is most useful for helper functions that 
#' define both data and aesthetics and shouldn't inherit behaviour from the 
#' default plot specification, e.g. borders.
#' @param ... other arguments passed on to layer. These are often aesthetics, 
#' used to set an aesthetic to a fixed value, like color = "red" or size = 3. 
#' They may also be parameters to the paired geom/stat.
#'
#' @return ggplot2 plot layer
#'
#' @examples
#' # default settings for normally distributed data, 95% confidence interval,  
#' data <- data.frame(x = rep(c(1, 2, 3), each = 20),
#'                    y = rep(c(1, 2, 3), each = 20) + stats::rnorm(60),
#'                    group = rep(1:3, 20))
#' xgx_plot(data, ggplot2::aes(x = x, y = y)) + 
#'   xgx_stat_ci(conf_level = 0.95)
#' 
#' # try different geom 
#' xgx_plot(data, ggplot2::aes(x = x, y = y)) + 
#'   xgx_stat_ci(conf_level = 0.95, geom = list("ribbon", "point", "line"))
#'  
#' # plotting lognormally distributed data
#' data <- data.frame(x = rep(c(1, 2, 3), each = 20),
#'                    y = 10^(rep(c(1, 2, 3), each = 20) + stats::rnorm(60)),
#'                    group = rep(1:3, 20))
#' xgx_plot(data, ggplot2::aes(x = x, y = y)) + 
#'   xgx_stat_ci(conf_level = 0.95, distribution = "lognormal")
#'   
#' # note: you DO NOT need to use both distribution = "lognormal"
#' # and scale_y_log10()
#' xgx_plot(data, ggplot2::aes(x = x, y = y)) + 
#'   xgx_stat_ci(conf_level = 0.95) + xgx_scale_y_log10()
#'  
#' # plotting binomial data
#' data <- data.frame(x = rep(c(1, 2, 3), each = 20),
#'                    y = stats::rbinom(60, 1, rep(c(0.2, 0.6, 0.8),
#'                    each = 20)),
#'                    group = rep(1:3, 20))
#' xgx_plot(data, ggplot2::aes(x = x, y = y)) + 
#'   xgx_stat_ci(conf_level = 0.95, distribution = "binomial")
#'  
#' # including multiple groups in same plot
#' xgx_plot(data, ggplot2::aes(x = x, y = y)) + 
#'   xgx_stat_ci(conf_level = 0.95, distribution = "binomial", 
#'               ggplot2::aes(color = factor(group)),
#'               position = ggplot2::position_dodge(width = 0.5))
#'  
#' @importFrom stats rnorm
#' @importFrom stats rbinom
#' @importFrom stats na.omit
#' @importFrom stats qt
#' @importFrom stats var
#' @importFrom binom binom.exact
#' @importFrom ggplot2 stat_summary
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 position_dodge
#' @export
xgx_stat_ci <- function(mapping = NULL, data = NULL, conf_level = 0.95,
                        distribution = "normal",
                        geom = list("point", "line", "errorbar"),
                        position = "identity",
                        fun.args = list(),
                        na.rm = FALSE,
                        show.legend = NA,
                        inherit.aes = TRUE,
                        ...) {
  if (!(conf_level > 0.5 && conf_level < 1)) {
    stop("conf_level should be greater than 0.5 and less than 1")
  }

  percentile_value <- conf_level + (1 - conf_level) / 2

  conf_int <- function(y, conf_level, distribution) {
    y <- stats::na.omit(y)

    if (distribution == "normal") {
      conf_int_out <- data.frame(
        y = mean(y),
        ymin = mean(y) - stats::qt(percentile_value,
                                   length(y)) * sqrt(stats::var(y) / length(y)),
        ymax = mean(y) + stats::qt(percentile_value,
                                   length(y)) * sqrt(stats::var(y) / length(y))
      )
    } else if (distribution == "lognormal") {
      yy <- log(y)
      conf_int_out <- data.frame(
        y = exp(mean(yy)),
        ymin = exp(mean(yy) - stats::qt(percentile_value, length(yy)) * sqrt(stats::var(yy) / length(yy))),
        ymax = exp(mean(yy) + stats::qt(percentile_value, length(yy)) * sqrt(stats::var(yy) / length(yy)))
      )
    } else if (distribution == "binomial") {
      conf_int_out <- data.frame(
        y = mean(y),
        ymin = binom::binom.exact(sum(y), length(y),
                                  conf.level = 0.95)$lower,
        ymax = binom::binom.exact(sum(y), length(y),
                                  conf.level = 0.95)$upper)
    } else {
      stop("distribution must be either normal, lognormal, or binomial")
    }
  }

  ret <- list()
  for (igeom in geom) {
    temp <- ggplot2::stat_summary(mapping = mapping, data = data,
                                  geom = igeom, position = position, ...,
                                  fun.args = list(), na.rm = na.rm,
                                  show.legend = show.legend,
                                  inherit.aes = inherit.aes,
                                  fun.data = function(y) conf_int(y, conf_level,
                                                                  distribution)
    )

    if (igeom == "point") {
      if (is.null(temp$aes_params$size)) temp$aes_params$size <- 2
    }
    else if (igeom == "line") {
      if (is.null(temp$aes_params$size)) temp$aes_params$size <- 1
    }
    else if (igeom == "errorbar") {
      if (is.null(temp$aes_params$size)) temp$aes_params$size <- 1
      if (is.null(temp$geom_params$width)) {
        temp$geom_params$width <- 0
      }
    }
    else if (igeom == "ribbon") {
      if(is.null(temp$aes_params$alpha)) temp$aes_params$alpha <- 0.25
    }
    else if (igeom == "pointrange") {
      if(is.null(temp$aes_params$size)) temp$aes_params$size <- 1
      temp$geom$geom_params$fatten <- 2
    }
    

    ret[[paste0("geom_", igeom)]] <- temp
  }

  return(ret)
}
