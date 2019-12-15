//+------------------------------------------------------------------+
//|                                                    zmqserver.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Zmq/Zmq.mqh>

extern int     MAGIC_ZMQ=7263459;
extern int     PUSH_Port=5554;
extern int     REP_Port=5555;
extern bool    Strategy_Tester=False;
extern bool    Verbose=False;
extern int     Take_Profit=20;
extern int     Stop_Loss=15;
input double   Lots=0.1;
input double   MaximumRisk=0.02;
input double   DecreaseFactor=3;
// CREATE ZeroMQ Context
Context context();

// CREATE ZMQ_REP SOCKET
Socket repSocket(context, ZMQ_REP);
Socket pushSocket(context, ZMQ_PUSH);

datetime lastBar;


bool IsNewBar(){
   bool retval = false;
   datetime curr = iTime(NULL,PERIOD_CURRENT,0);
   if(lastBar != curr) // new candle on lastBar
   {
      retval = true;
      lastBar = curr;    // overwrite old with new value
   }
   return retval;
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetMillisecondTimer(100);     // Set 100 Millisecond Timer to get client socket input

   context.setBlocky(false);
   repSocket.setSendHighWaterMark(1);
   pushSocket.setSendHighWaterMark(1);
   repSocket.setLinger(1);
   pushSocket.setLinger(1);
   
   if(Verbose){
      Print(StringFormat("Connecting Socket on Port %d ...", REP_Port));
   }
   repSocket.bind("tcp://*:"+IntegerToString(REP_Port));
   pushSocket.bind("tcp://*:"+IntegerToString(PUSH_Port));
   
   lastBar = iTime(NULL,PERIOD_CURRENT,0);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
   // closing all open trades
   for (int cnt=OrdersTotal()-1; cnt>=0; cnt--) 
   if (OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES) && OrderCloseTime()==0 && OrderMagicNumber()==MAGIC_ZMQ)
      bool i2= (OrderType()<2) ? OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),3,Red) :
                                 OrderDelete(OrderTicket());
   
   if(Verbose){
      Print(StringFormat("Unbinding Socket on Port %d ...", REP_Port));
   }
   repSocket.unbind("tcp://*:" + IntegerToString(REP_Port));
   repSocket.disconnect("tcp://*:" + IntegerToString(REP_Port));
   pushSocket.unbind("tcp://*:" + IntegerToString(PUSH_Port));
   pushSocket.disconnect("tcp://*:" + IntegerToString(PUSH_Port));   
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   // OnTimer not implemented in Strategy Tester so a shortcut here
   if(Strategy_Tester) {
      for(int i=0; i < 1; i++){
         OnTimer();
      }
   }
}
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC_ZMQ)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }

double AccountPercentStopPips(string symbol, double percent, double lots)
{
    double balance   = AccountBalance();
    double tickvalue = MarketInfo(symbol, MODE_TICKVALUE);
    double lotsize   = MarketInfo(symbol, MODE_LOTSIZE);
    double spread    = MarketInfo(symbol, MODE_SPREAD);

    double stopLossPips = percent * balance / (lots * lotsize * tickvalue) - spread;

    return (stopLossPips);
}

void MakeOrders(string req){
   int res;
   // Only make orders if no current order
   if(CalculateCurrentOrders(Symbol())==0){ 
      int lots = 1;
      if(req == "buy"){
         res=OrderSend(Symbol(),OP_BUY,lots,Ask,3,Bid-Stop_Loss*Point,Bid+Take_Profit*Point,"",MAGIC_ZMQ,0,Blue);
      }else if(req == "sell"){
         res=OrderSend(Symbol(),OP_SELL,lots,Bid,3,Ask+Stop_Loss*Point, Ask-Take_Profit*Point,"",MAGIC_ZMQ,0,Red);
      }
   }
}


void HandleRequest(string req){
   if(req == "get"){
      //do nothing, client will automatically get price update on every request as answer
   }else{
      MakeOrders(req);
   }
}

uchar _data[];
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(){
//---
   ZmqMsg request;
   
   repSocket.recv(request, true);
   if(request.size() > 0) {
      // Get data from request   
      ArrayResize(_data, request.size());
      request.getData(_data);
      string dataStr = CharArrayToString(_data);
      if(Verbose){
         Print(dataStr);
      }
      
      HandleRequest(dataStr);
      
      string replyString = "response\nno price update";
      
      if(IsNewBar()) {
         if(Verbose){
            Print("refreshed");
         }
         replyString = "Close";
      
         for(int i=0; i < 100; i++){
            StringAdd(replyString, StringFormat("\n%lf", iClose(NULL, PERIOD_CURRENT, i)));
         }
      }
      
      ZmqMsg reply(replyString);
      repSocket.send(reply);
      
      }
  }
//+------------------------------------------------------------------+
