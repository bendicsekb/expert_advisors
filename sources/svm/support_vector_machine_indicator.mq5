//+------------------------------------------------------------------+
//|                             Support Vector Machine Indicator.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+---------Support Vector Machine Learning Tool Functions-----------+
//| The following #import statement imports all of the support vector
//| machine learning tool functions into the indicator for use. Please note, if
//| you do not import the functions here, the compiler will not let you
//| use any of the functions
//+------------------------------------------------------------------+
#import "svMachineTool.ex5"
enum ENUM_TRADE {BUY,SELL};
enum ENUM_OPTION {OP_MEMORY,OP_MAXCYCLES,OP_TOLERANCE};
int  initSVMachine(void);
void setIndicatorHandles(int handle,int& indicatorHandles[],int& Offsets[], int startBar,int N);
void setIndicatorHandles(int handle,int &indicatorHandles[],int startBar,int N);
void setParameter(int handle,ENUM_OPTION option,double value);
bool genOutputs(int handle,ENUM_TRADE trade,int StopLoss,int TakeProfit,double duration);
bool genInputs(int handle);
bool setInputs(int handle,double &Inputs[],int nInputs);
bool setOutputs(int handle,bool &Outputs[]);
bool getTrainingData(int handle,double &Inputs[],bool &Outputs[]);
bool training(int handle);
bool classify(int handle);
bool classify(int handle,int offset);
bool classify(int handle,double &iput[]);
void  deinitSVMachine(void);
#import

#property description "This indicator uses support vector machines to analyse indicator data and signal future trades."
#property description "Buy trades are signalled by a green ‘up’ arrow with sell trades signalled by a red ‘down’ arrow."
#property description "This indicator uses the Support Vector Machine Learning Library available from the metaquotes "
#property description "market place to achieve support vector machine functionality."

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   2

#property indicator_label1  "Buy Arrow"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGreen
#property indicator_width1  5

#property indicator_label2  "Sell Arrow"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  5

//+---------------------Indicator Variables--------------------------+
//| Only the default indicator variables have been used here. I
//| recommend you play with these values to see if you get any 
//| better performance with the indicator.                    
//+------------------------------------------------------------------+
int bears_period=13;
int bulls_period=13;
int ATR_period=13;
int mom_period=13;
int MACD_fast_period=12;
int MACD_slow_period=26;
int MACD_signal_period=9;
int Stoch_Kperiod=5;
int Stoch_Dperiod=3;
int Stoch_slowing=3;
int Force_period=13;

datetime input TrainingDate;     //All historical data used for training the support vector machine will be from prior to this date.
int input      N_DataPoints=500; //Specifies the number of training points to be used when training the SVM
input int      takeProfit=80;    //TakeProfit level measured in pips for hypothetical trades
input int      stopLoss=80;      //StopLoss level measured in pips for hypothetical trades
input double   hours=10;         //The maximum hypothetical trade duration for calculating training outputs.
input double   Tolerance_Value=0.1; //Error Tolerance value for training the svm (default is 10%)

int            handles[];     //creates an array with 2 rows to store the indicator handles/offsets
double         BuyBuffer[],SellBuffer[];  //Buffers to store data for plotting buy/sell arrows
int            handleB,handleS;  //handle values for the buy/sell support vector machines
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//Initializes the buy arrow buffers
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,241);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//Initializes the sell arrow buffers
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   ArraySetAsSeries(SellBuffer,true);
   PlotIndexSetInteger(1,PLOT_ARROW,242);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

   ArrayResize(handles,7);ArrayInitialize(handles,0); //Resize the handles array and initialize with zeros values.
//+------------------------------------------------------------------+
//| The following statements are used to initialize the indicators to be used for the support 
//| vector machine. The handles returned are stored to an int[] array. I have used standard 
//| indicators in this case however, you can also you custom indicators if desired.
//+------------------------------------------------------------------+
   handles[0]=iBearsPower(Symbol(),0,bears_period);
   handles[1]=iBullsPower(Symbol(),0,bulls_period);
   handles[2]=iATR(Symbol(),0,ATR_period);
   handles[3]=iMomentum(Symbol(),0,mom_period,PRICE_TYPICAL);
   handles[4]=iMACD(Symbol(),0,MACD_fast_period,MACD_slow_period,MACD_signal_period,PRICE_TYPICAL);
   handles[5]=iStochastic(Symbol(),0,Stoch_Kperiod,Stoch_Dperiod,Stoch_slowing,MODE_SMA,STO_LOWHIGH);
   handles[6]=iForce(Symbol(),0,Force_period,MODE_SMA,VOLUME_TICK);

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   deinitSVMachine();    //deinitializes the support vector machines
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

//+------------------------------------------------------------------+
//| This statement is called the first time the indicator is attached to the chart
//| Training outputs from the support vector machine are used to create buy/sell
//| on the current bars on the chart.
//+------------------------------------------------------------------+
   if(prev_calculated==0)
     {
      int offset=0;
      //----------Initialize, Setup and Training of the Buy-Signal support vector machine----------
      handleB=initSVMachine();            //initializes a new SVM and stores the handle to 'handleB'
      setIndicatorHandles(handleB,handles,offset,N_DataPoints);   //passes the initialized indicators to the SVM with desired offset and number of data points
      setParameter(handleB,OP_TOLERANCE,Tolerance_Value);   //Sets the maximum error tolerance for SVM training
      genInputs(handleB);               //generate inputs using the initialized indicators
      genOutputs(handleB,BUY,stopLoss,takeProfit,hours);   //generates the outputs based on the desired parameters for taking hypothetical trades

      //----------Initialize, Setup and Training of the Sell-Signal support vector machine----------
      handleS=initSVMachine();            //initializes a new SVM and stores the handle to 'handleS'
      setIndicatorHandles(handleS,handles,offset,N_DataPoints);   //passes the initialized indicators to the SVM with desired offset and number of data points
      setParameter(handleS,OP_TOLERANCE,Tolerance_Value);   //Sets the maximum error tolerance for SVM training
      genInputs(handleS);               //generate inputs using the initialized indicators
      genOutputs(handleS,SELL,stopLoss,takeProfit,hours);   //generates the outputs based on the desired parameters for taking hypothetical trades

      training(handleB);      //executes training on the Buy-Signal support vector machine
      training(handleS);      //executes training on the Sell-Signal support vector machine

      bool buys[],sells[];    //create two boolean arrays
      double unused[];        //Creates a double array that is unused
      getTrainingData(handleB,unused,buys);  //retrieves the training data from the buy-signal SVM
      getTrainingData(handleS,unused,sells); //retrieves the training data from the sell-signal SVM

      for(int i=0;i<ArraySize(buys);i++)
        {
         if(buys[ArraySize(buys)-i-1])    BuyBuffer[i]=open[rates_total-i-1];
         else                             BuyBuffer[i]=0;
        }
      for(int i=0;i<ArraySize(sells);i++)
        {
         if(sells[ArraySize(sells)-i-1])  SellBuffer[i]=open[rates_total-i-1];
         else                             SellBuffer[i]=0;
        }
     }

//+------------------------------------------------------------------+
//| This statement is called for the calculation of any new bar generated on the 
//| current chart timeframe. It uses the model created by the trained support vector
//| machine to signal buy/sell trades and indicates with arrows
//+------------------------------------------------------------------+
   if(rates_total!=prev_calculated && prev_calculated>0)
     {
      for(int i=(rates_total-prev_calculated-1);i>0;i--)
        {
         if(classify(handleB,i))    BuyBuffer[i]=open[rates_total-i-1];
         else                       BuyBuffer[i]=0;
         if(classify(handleS,i))    SellBuffer[i]=open[rates_total-i-1];
         else                       SellBuffer[i]=0;
        }
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
