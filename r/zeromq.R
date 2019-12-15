library(fpp2)
library(rzmq)

# INIT
verbose <- TRUE
#zmq
context <- init.context()
socket <- init.socket(context, "ZMQ_REQ" )
set.linger(socket, integer(1))
connect.socket(socket, "tcp://localhost:5555")
send.socket(socket, charToRaw("HI"), serialize = FALSE)
str_request <- "get"
#logic
profit_pips = 3 * 0.00010
s_l_pips = 3 * 0.00010
# END INIT

# FUNCTIONS
#zmq
no_price <- function(data) {
  return(data[1] == "no price update")
}
#logic
open_trade <- function(buy, sell, msg){
  retval <-"no action..."
  str_request <- "get"
  if(buy){
    str_request <- "buy"
    retval <- "sending buy signal..."
  }
  if(sell){
    str_request <- "sell"
    retval <- "sending sell signal..."
  }
  
  return(c(retval, str_request))
}

buy_signal <- function(last, min, max){
  return((last <= min + s_l_pips) && (max > last + profit_pips))
}

sell_signal <- function(last, min, max){
  return((last >= max - s_l_pips) && (min < last - profit_pips))
}
# END FUNCTIONS

while(1){

  received = receive.socket(socket, unserialize = FALSE, dont.wait = TRUE)
  
  if(length(received) > 0){
    data <- rev(t(read.csv(text=rawToChar(received))))
    if(verbose){
      print(head(data)) 
    }
    
    send.socket(socket, charToRaw(str_request), serialize = FALSE)
    
    str_request <- "get"
    
    # exit if no new price
    if(no_price(data)){
      next()
    }
    
    # logic (predict and send)
    past_data <- data
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
    trade <- open_trade(buy = buy_signal(last_val, minima, maxima), sell = sell_signal(last_val, minima, maxima), msg = str_request)
    str_request <- trade[2]
    if(verbose){
      print(trade)
    }
  }
}


