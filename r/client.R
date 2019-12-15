library(fpp2)

profit_pips = 10 * 0.00010
s_l_pips = 0.5 * 0.00010

get_data <- function(i=1){
  width <- 100
  window <- seq(from = ((i-1)*width)+1, to=(i*width))
  return(data[window,3])
}

open_trade <- function(buy, sell){
  if(buy){
    return("buy signal sent...")
  }
  if(sell){
    return("sell signal sent...")
  }
  return("no action...")
}

buy_signal <- function(last, min, max){
  return((last <= min + s_l_pips) && (max > last + profit_pips))
}

sell_signal <- function(last, min, max){
  return((last >= max - s_l_pips) && (min < last - profit_pips))
}


past_data <- get_data()
serie <- ts(data = past_data, start=1, frequency = 2*pi)
fit <- stl(serie, t.window = 13, s.window = "periodic", robust = TRUE)
seas <- seasonal(fit)
trend <- trendcycle(fit)
rem <- remainder(fit)
fs <- stlf(seas)
ft <- stlf(trend)
fr <- stlf(rem)
guess <- fs[["mean"]] + ft[["mean"]] + fr[["mean"]]
last_val <- tail(past_data, 1)
minima <- min(guess)
maxima <- max(guess)
print(open_trade(buy = buy_signal(last_val, minima, maxima), sell = sell_signal(last_val, minima, maxima)))

