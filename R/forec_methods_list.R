#' Forecasting methods list
#' A list of the forecasting methods for use in the metalearnig process
#' The list follows the format described in the parameter \code{methods}
#' of \code{\link{calc_forecasts}}
#' @seealso \code{\link{calc_forecasts}}
#' @export
forec_methods <- function() {
  methods_list <- list("auto_arima_forec")
  methods_list <- append(methods_list, "ets_forec")
  methods_list <- append(methods_list, "nnetar_forec")
  methods_list <- append(methods_list, "tbats_forec")
  methods_list <- append(methods_list, "stlm_ar_forec")
  methods_list <- append(methods_list, "rw_drift_forec")
  methods_list <- append(methods_list, "thetaf_forec")
  methods_list <- append(methods_list, "naive_forec")
  methods_list <- append(methods_list, "snaive_forec")
  methods_list
}

#' @describeIn forec_methods forecast::snaive
#' @param x A \code{ts} object with the input time series
#' @param h The amount of future time steps to forecast
#' @export
snaive_forec <- function(x,h) {
  #model <- forecast::snaive(x, h=length(x))
  #forecast::forecast(model, h=h)$mean
  frq <- stats::frequency(x) #maybe faster calculation
  utils::tail(x,frq)[((1:h -1) %% frq) + 1]
}

#' @describeIn forec_methods forecast::naive
#' @export
naive_forec <- function(x,h) {
  model <- forecast::naive(x, h=length(x))
  forecast::forecast(model, h=h)$mean
}

#' @describeIn forec_methods forecast::auto.arima
#' @export
auto_arima_forec <- function(x, h) {
  model <- forecast::auto.arima(x, stepwise=FALSE, approximation=FALSE)
  forecast::forecast(model, h=h)$mean
}

#' @describeIn forec_methods forecast::ets
#' @export
ets_forec <- function(x, h) {
  model <- forecast::ets(x) # undo opt.crit="mae" change for obc implementation
  forecast::forecast(model, h=h)$mean
}

#' @describeIn forec_methods forecast::nnetar
#' @export
nnetar_forec <- function(x, h) {
  model <- forecast::nnetar(x)
  forecast::forecast(model, h=h)$mean
}

#' @describeIn forec_methods forecast::tbats
#' @export
tbats_forec <- function(x, h) {
  model <- forecast::tbats(x, use.parallel=FALSE)
  forecast::forecast(model, h=h)$mean
}


#' @describeIn forec_methods forecast::stlm with ar modelfunction
#' @export
stlm_ar_forec <- function(x, h) {
  model <- tryCatch({
    forecast::stlm(x, modelfunction = stats::ar)
  }, error = function(e) forecast::auto.arima(x, d=0,D=0))
  forecast::forecast(model, h=h)$mean
}

#' @describeIn forec_methods forecast::rwf
#' @export
rw_drift_forec <- function(x, h) {
  model <- forecast::rwf(x, drift=TRUE, h=length(x))
  forecast::forecast(model, h=h)$mean
}


#' @describeIn forec_methods forecast::thetaf
#' @export
thetaf_forec <- function(x, h) {
  forecast::thetaf(x, h=h)$mean
}


#Test used to determine whether a time series is seasonal
SeasonalityTest <- function(input, ppy) {
  tcrit <- 1.645
  if (length(input) < 3 * ppy) {
    test_seasonal <- FALSE
  } else {
    xacf <- stats::acf(input, plot = FALSE)$acf[-1, 1, 1]
    clim <-
      tcrit / sqrt(length(input)) * sqrt(cumsum(c(1, 2 * xacf ^ 2)))
    test_seasonal <- (abs(xacf[ppy]) > clim[ppy])

    if (is.na(test_seasonal) == TRUE) {
      test_seasonal <- FALSE
    }
  }

  return(test_seasonal)
}


#' @describeIn forec_methods Naive2 method from the M4 competition, used for the OWA
#' @export
naive2_forec <- function(x, h) {
  input <- x
  fh <- h
  #Estimate seasonaly adjusted time series
  ppy <- stats::frequency(input)
  ST <- FALSE
  if (ppy > 1) {
    ST <- SeasonalityTest(input, ppy)
  }
  if (ST == TRUE) {
    Dec <- stats::decompose(input, type = "multiplicative")
    des_input <- input / Dec$seasonal
    SIout <-
      utils::head(rep(Dec$seasonal[(length(Dec$seasonal) - ppy + 1):length(Dec$seasonal)], fh), fh)
  } else{
    des_input <- input
    SIout <- rep(1, fh)
  }

  forecast::naive(des_input, h=fh)$mean*SIout
}
