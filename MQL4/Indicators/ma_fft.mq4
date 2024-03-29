//+--------------------------------------------------------------------------------------+
//|                                                                     Extrapolator.mq4 |
//|                                                               Copyright © 2008, gpwr |
//|                                                                   vlad1004@yahoo.com |
//+--------------------------------------------------------------------------------------+
#property copyright "Copyright © 2008, gpwr"
#property indicator_chart_window
#property indicator_color1 Blue, LightSeaGreen
#property indicator_color2 Red
#property indicator_width1 2
#property indicator_width2 2
#property indicator_buffers 4


//Global constants
#define pi 3.141592653589793238462643383279502884197169399375105820974944592

//Input parameters
extern int     MAPeriod =5;     //Moving Average Period
extern int     LastBar  =50;    //Last bar in the past data
extern int     PastBars =70;   //Number of past bars
extern double  LPOrder  =0.6;   //Order of linear prediction model; 0 to 1
//LPOrder*PastBars specifies the number of prediction coefficients a[1..LPOrder*PastBars] where a[0]=1
extern int     FutBars  =30;   //Number of bars to predict; for LP is set at PastBars-Order-1 
extern int     HarmNo   =20;    //Number of frequencies for Method 1; HarmNo=0 computes PastBars harmonics
extern double  FreqTOL  =0.0001;//Tolerance of frequency calculation for Method 1
//FreqTOL > 0.001 may not converge
//extern int     BurgWin  =0;     //Windowing function for Weighted Burg Method; 0=no window 1=Hamming 2=Parabolic

//Indicator buffers
double pv[];
double fv[];
double ma[];

//Global variables
double ETA,INFTY,SMNO;
int np,nf,lb,no,it;

int init()
{
   lb=LastBar;
   np=PastBars;
   no=LPOrder*PastBars;
   nf=FutBars;
   if(HarmNo==0) HarmNo=np;
   
   //set_color_scheme(IndicatorColorScheme);
   
   IndicatorBuffers(4);
   SetIndexBuffer(0,pv);
   SetIndexBuffer(1,fv);
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2);
   SetIndexShift(0,-lb);//past data vector 0..np-1; 0 corresponds to bar=lb
   SetIndexShift(1,nf-lb);//future data vector i=0..nf; nf corresponds to bar=lb
   IndicatorShortName("Extrapolator");  
   return(0);
}

int deinit(){return(0);}



int start()
{
   ArrayInitialize(pv,EMPTY_VALUE);
   ArrayInitialize(fv,EMPTY_VALUE);  
   
   double curr=0.0;
//   for(int i=0;i<np;i++) opens[i]=Open[i+lb];
// Filling ma with moving averages
   ArrayResize(ma, np);
   for(int i=0;i<np;i++) 
   {
      curr=iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_OPEN,i+lb);
      ma[i]=curr;
   }

//Find average of past values
   double av=0.0;
   for(i=0;i<np;i++) av+=ma[i];
   av/=np;
   

//Prepare data
   for(i=0;i<np;i++)
   {
      pv[i]=av;
      if(i<=nf) fv[i]=av;
   }

// Extrapolate
   double w,m,c,s;
   for(int harm=0;harm<HarmNo;harm++)
   {
      Freq(w,m,c,s);
      for(i=0;i<np;i++) 
      {
         pv[i]+=m+c*MathCos(w*i)+s*MathSin(w*i);
         if(i<=nf) fv[i]+=m+c*MathCos(w*i)-s*MathSin(w*i);
      }         
   }

//Reorder the predicted vector
   for(i=0;i<=(nf-1)/2;i++)
   {
      double tmp=fv[i];
      fv[i]=fv[nf-i];
      fv[nf-i]=tmp;
   } 
   return(0); 
}
//+--------------------------------------------------------------------------------------+
//Quinn and Fernandes algorithm
void Freq(double& w, double& m, double& c, double& s)
{
   double z[],num,den;
   ArrayResize(z,np);
   double a=0.0;
   double b=2.0;
//   z[0]=Open[lb]-pv[0];
   
   z[0]=ma[0]-pv[0];
   
   while(MathAbs(a-b)>FreqTOL)
   {
      a=b;
//      z[1]=Open[1+lb]-pv[1]+a*z[0];

      z[1]=ma[1]-pv[1]+a*z[0];
      
      num=z[0]*z[1];
      den=z[0]*z[0];
      for(int i=2;i<np;i++)
      {
         //z[i]=Open[i+lb]-pv[i]+a*z[i-1]-z[i-2];
         
         z[i]=ma[i]-pv[i]+a*z[i-1]-z[i-2];
         
         num+=z[i-1]*(z[i]+z[i-2]);
         den+=z[i-1]*z[i-1];
      }
      b=num/den;
   }
   w=MathArccos(b/2.0);
   Fit(w,m,c,s);
   return;
}
//+-------------------------------------------------------------------------+
void Fit(double w, double& m, double& c, double& s)
{
   double Sc=0.0;
   double Ss=0.0;
   double Scc=0.0;
   double Sss=0.0;
   double Scs=0.0;
   double Sx=0.0;
   double Sxx=0.0;
   double Sxc=0.0;
   double Sxs=0.0;
   for(int i=0;i<np;i++)
   {
      double cos=MathCos(w*i);
      double sin=MathSin(w*i);
      Sc+=cos;
      Ss+=sin;
      Scc+=cos*cos;
      Sss+=sin*sin;
      Scs+=cos*sin;
      //Sx+=(Open[i+lb]-pv[i]);
      //Sxx+=MathPow(Open[i+lb]-pv[i],2);
      //Sxc+=(Open[i+lb]-pv[i])*cos;
      //Sxs+=(Open[i+lb]-pv[i])*sin;
      
      Sx+=(ma[i]-pv[i]);
      Sxx+=MathPow(ma[i]-pv[i],2);
      Sxc+=(ma[i]-pv[i])*cos;
      Sxs+=(ma[i]-pv[i])*sin;
      
   }
   Sc/=np;
   Ss/=np;
   Scc/=np;
   Sss/=np;
   Scs/=np;
   Sx/=np;
   Sxx/=np;
   Sxc/=np;
   Sxs/=np;
   if(w==0.0)
   {
      m=Sx;
      c=0.0;
      s=0.0;
   }
   else
   {
      //calculating c, s, and m
      double den=MathPow(Scs-Sc*Ss,2)-(Scc-Sc*Sc)*(Sss-Ss*Ss);
      c=((Sxs-Sx*Ss)*(Scs-Sc*Ss)-(Sxc-Sx*Sc)*(Sss-Ss*Ss))/den;
      s=((Sxc-Sx*Sc)*(Scs-Sc*Ss)-(Sxs-Sx*Ss)*(Scc-Sc*Sc))/den;
      m=Sx-c*Sc-s*Ss;
   }
   return;
}
