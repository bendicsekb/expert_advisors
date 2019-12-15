//+------------------------------------------------------------------+
//|                              Visual Position Size Calculator.mq4 |
//|                                                       Josh Jones |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Josh Jones"
#property link      ""


#define FONT "Tahoma"
#define START_X 50
#define START_Y 50
#define LINE_SPACE_1 20
#define LINE_SPACE_2 15

#define SL_LINE_TEXT        "SL_LINE_TEXT"
#define PRICE_LINE_TEXT     "PRICE_LINE_TEXT"
#define LOTS_LABEL_TEXT     "LOTS_LABEL"
#define ORDER_LABEL_TEXT    "ORDER_LABEL"
#define SL_LABEL_TEXT       "SL_LABEL"
#define LEV_LABEL_TEXT      "LEV_LABEL"
#define PIP_VAL_LABEL_TEXT  "PIP_VAL_LABEL"
#define RISK_LABEL_TEXT     "RISK_LABEL"

//---- input parameters
extern double PercentToRisk = 2.0;
extern bool PendingOrder = true;
extern bool ShowDetailedInfo = true;
extern color TextColor = Gold;

int pippette = 1;

string displayString = "";
string symbol = "";
string baseCurr = "";
string quoteCurr = "";
string acctCurr = "";

double lotsToTrade = -1;
double _bid = 0;
double _ask = 0;
double priceVal = 0;
double slVal = 0;
double amtRisked = 0;

double tickSize = 0;
double lotSize = 0;

double spread = 0;
double slSizeInPips = 0;
double trueSL = 0;
double pipValue = 0;

string lotStr = "";
string orderStr = "";
string slStr = "";
string levStr = "";
string pipValStr = "";
string riskStr = "";


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {

   int y = START_Y;

   if (MarketInfo("EURUSD",MODE_DIGITS) == 5)
      pippette = 10;
   
   ObjectCreate(SL_LINE_TEXT,OBJ_HLINE,0,0,iHigh(Symbol(),PERIOD_D1,0));
   ObjectSet(SL_LINE_TEXT,OBJPROP_STYLE,STYLE_DOT);
   ObjectSet(SL_LINE_TEXT,OBJPROP_COLOR,Red);

   if (PendingOrder)
   {
      ObjectCreate(PRICE_LINE_TEXT,OBJ_HLINE,0,0,iLow(Symbol(),PERIOD_D1,0));
      ObjectSet(PRICE_LINE_TEXT,OBJPROP_STYLE,STYLE_DOT);
      ObjectSet(PRICE_LINE_TEXT,OBJPROP_COLOR,Green);
   }

   ObjectCreate(LOTS_LABEL_TEXT,OBJ_LABEL,0,0,0,0,0);
   ObjectSet(LOTS_LABEL_TEXT,OBJPROP_XDISTANCE,START_X);
   ObjectSet(LOTS_LABEL_TEXT,OBJPROP_YDISTANCE,y);

   if (ShowDetailedInfo)
   {
      y += LINE_SPACE_1;

      ObjectCreate(ORDER_LABEL_TEXT,OBJ_LABEL,0,0,0,0,0);
      ObjectSet(ORDER_LABEL_TEXT,OBJPROP_XDISTANCE,START_X);
      ObjectSet(ORDER_LABEL_TEXT,OBJPROP_YDISTANCE,y);

      y += LINE_SPACE_2;

      ObjectCreate(SL_LABEL_TEXT,OBJ_LABEL,0,0,0,0,0);
      ObjectSet(SL_LABEL_TEXT,OBJPROP_XDISTANCE,START_X);
      ObjectSet(SL_LABEL_TEXT,OBJPROP_YDISTANCE,y);

      y += LINE_SPACE_2;

      ObjectCreate(LEV_LABEL_TEXT,OBJ_LABEL,0,0,0,0,0);
      ObjectSet(LEV_LABEL_TEXT,OBJPROP_XDISTANCE,START_X);
      ObjectSet(LEV_LABEL_TEXT,OBJPROP_YDISTANCE,y);

      y += LINE_SPACE_2;

      ObjectCreate(PIP_VAL_LABEL_TEXT,OBJ_LABEL,0,0,0,0,0);
      ObjectSet(PIP_VAL_LABEL_TEXT,OBJPROP_XDISTANCE,START_X);
      ObjectSet(PIP_VAL_LABEL_TEXT,OBJPROP_YDISTANCE,y);

      y += LINE_SPACE_2;

      ObjectCreate(RISK_LABEL_TEXT,OBJ_LABEL,0,0,0,0,0);
      ObjectSet(RISK_LABEL_TEXT,OBJPROP_XDISTANCE,START_X);
      ObjectSet(RISK_LABEL_TEXT,OBJPROP_YDISTANCE,y);
   }

 
   start();   
   
//----
   return(0);
  }


void CleanUp()
{
   ObjectDelete(SL_LINE_TEXT);

   if (PendingOrder)
      ObjectDelete(PRICE_LINE_TEXT);

   ObjectDelete(LOTS_LABEL_TEXT);

   if (ShowDetailedInfo)
   {
      ObjectDelete(ORDER_LABEL_TEXT);
      ObjectDelete(SL_LABEL_TEXT);
      ObjectDelete(LEV_LABEL_TEXT);
      ObjectDelete(PIP_VAL_LABEL_TEXT);
      ObjectDelete(RISK_LABEL_TEXT);
   }
}   


//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {

      switch(UninitializeReason())
      {
        case REASON_CHARTCLOSE:
        case REASON_REMOVE:      CleanUp(); break; // cleaning up and deallocation of all resources.
      }
   
   return(0);
  }



double calcLots()
{
   displayString = "";
   symbol = Symbol();
   baseCurr = StringSubstr(symbol,0,3);
   quoteCurr = StringSubstr(symbol,3,3);
   acctCurr = AccountCurrency();

   lotsToTrade = -1;
   _bid = MarketInfo(symbol,MODE_BID);
   _ask = MarketInfo(symbol,MODE_ASK);
   
   if (PendingOrder)
      priceVal = ObjectGet(PRICE_LINE_TEXT,OBJPROP_PRICE1);
   else
      priceVal = _bid;
      
   slVal = ObjectGet(SL_LINE_TEXT,OBJPROP_PRICE1);
   amtRisked = 0.01 * PercentToRisk * MathMin(AccountEquity(),AccountBalance());

   tickSize = MarketInfo(symbol,MODE_TICKSIZE);
   lotSize = MarketInfo(symbol,MODE_LOTSIZE);

   spread = MarketInfo(symbol,MODE_SPREAD);
   slSizeInPips = MathAbs(priceVal - slVal) / Point;
   trueSL = slSizeInPips + spread;
   pipValue = amtRisked / slSizeInPips;

   double posSize = amtRisked / tickSize / trueSL;

   if (quoteCurr == acctCurr)   // Direct Rate , e.g. deposit currency is USD and EUR/USD, or GBP/USD
   {
   }
   else if (baseCurr == acctCurr)  // Indirect Rate , e.g. deposit currency is USD and using USD/JPY or USD/CHF
   {
      posSize *= _bid;
   }
   else  // cross rate
   {
      double cross1 = MarketInfo(quoteCurr + acctCurr,MODE_BID);
      double cross2 = MarketInfo(acctCurr + quoteCurr,MODE_BID);
      if (cross1 > 0) // cross rate where Acct currency is a QUOTE for the current rate's QUOTE (e.g., EUR/GBP  ==>  GBP/USD)
      {
         posSize /= cross1;
      }
      else if (cross2 > 0)  // cross rate where Acct currency is a BASE for the current rate's QUOTE (e.g., EUR/JPY  ==>  USD/JPY)
      {
         posSize *= cross2;
      }
   }

   lotsToTrade = posSize / lotSize;
   lotStr = "Trade " + DoubleToStr(lotsToTrade,2) + " Lots";


   if (ShowDetailedInfo)
   {
   
      if (PendingOrder)
      {
         if (priceVal >= _bid)
         {
            if (slVal < priceVal)
               orderStr = "Order Type:  Buy Stop";
            else
               orderStr = "Order Type:  Sell Limit";
         }
         else
         {
            if (slVal < priceVal)
               orderStr = "Order Type:  Buy Limit";
            else
               orderStr = "Order Type:  Sell Stop";
         }
      }
      else
      {
         if (priceVal >= slVal)
            orderStr = "Order Type:  Buy Market";
         else
            orderStr = "Order Type:  Sell Market";
      }

      slStr = "True SL:  " + DoubleToStr(trueSL/pippette,1) + " pips (" + DoubleToStr(slSizeInPips/pippette,1) +
         " pip SL + " + DoubleToStr(spread/pippette,1) + " pip spread)";

      levStr = "True Leverage:  " + DoubleToStr(posSize/AccountBalance(),1) + ":1";

      pipValStr = "1 pip worth:  " + acctCurr + " " + DoubleToStr(pipValue*pippette,2);

      riskStr = "Total Risk:  " + acctCurr + " " + DoubleToStr(amtRisked,2) + " (" + DoubleToStr(PercentToRisk,1) + "%)";
   }

   return (lotsToTrade);
}


//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {

   while(!IsStopped())
   {
      if (calcLots() < 0)
      {
         ObjectSetText(LOTS_LABEL_TEXT,"Error Calculating Position Size",14,FONT,TextColor);
         if (ShowDetailedInfo)
         {
            ObjectSetText(ORDER_LABEL_TEXT,"",0);
            ObjectSetText(SL_LABEL_TEXT,"",0);
            ObjectSetText(LEV_LABEL_TEXT,"",0);
            ObjectSetText(PIP_VAL_LABEL_TEXT,"",0);
            ObjectSetText(RISK_LABEL_TEXT,"",0);
         }
      }         
      else
      {
         ObjectSetText(LOTS_LABEL_TEXT,lotStr,14,FONT,TextColor);
         if (ShowDetailedInfo)
         {
            ObjectSetText(ORDER_LABEL_TEXT,orderStr,10,FONT,TextColor);
            ObjectSetText(SL_LABEL_TEXT,slStr,10,FONT,TextColor);
            ObjectSetText(LEV_LABEL_TEXT,levStr,10,FONT,TextColor);
            ObjectSetText(PIP_VAL_LABEL_TEXT,pipValStr,10,FONT,TextColor);
            ObjectSetText(RISK_LABEL_TEXT,riskStr,10,FONT,TextColor);
         }
      }

      WindowRedraw();
      Sleep(300);
   }

   return(0);
  }
//+------------------------------------------------------------------+