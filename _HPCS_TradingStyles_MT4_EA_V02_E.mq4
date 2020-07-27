//+------------------------------------------------------------------+
//|                             _HPCS_TradingStyles_MT4_EA_V02_E.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property icon      "\\Files\\hpcs_logo.ico"
#property link      "http://www.hpcsphere.com"
#property copyright "Copyright 2011-2018, HPC Sphere Pvt. Ltd. India."
#define   VERSION   "2.00"
#property version   VERSION
#property description "Trading Strategy Based on Pin Bar Long Wick Rejection "
#property strict
//#include  <HPCSMetatraderExpiryCompilation.mqh>

int c=0;
datetime gdt_prev;
//--ENUM for Money Management---
enum ge_mm{ Fixed_amount,
            Percentage_of_account,
            Lot_using_risk};
//----ENUM For Indicator
enum ge_indicator {
                    MACD,
                    MA,
                    Pivot,
                    MA_and_MACD,
                    MA_and_Pivot,
                    MACD_and_Pivot,
                    MACD_and_MA_and_Pivot
                    };
//------ENUM for Operation Type                  
enum ge_opType{ 
                  Buy,
                  Sell,
                  Both_Buy_and_Sell,
                  According_to_Signal
              };

//-------------------------Inputs for EA  
extern int choice = 3;                                       //to Skip Signal If continuous Loss
extern ge_indicator  ge_operation       =MACD;               //Indicator Type
extern ge_mm    MoneyManagement         =Fixed_amount;      //Lot size management behaviours
extern ge_opType  type                  =Both_Buy_and_Sell;
extern int      gi_fastema              =12;                //Fast EMA MACD
extern int      gi_slowema              =16;                //Slow EMA MACD
extern int      gi_period               =9;                 //Period MACD
extern double   gi_pos                  =10;                //Positive Range in points
extern double   gi_neg                  =-10;               //Negative Range in points
input  int      gi_fmaPeriod            =30;                //Fast MA Period
input  int      gi_smaPeriod            =5;                 //Slow MA Period
input  int      gi_barallowed           =50;                 //Bars allowed for pending Order
extern int gi_slp=10;
input int id_tp=0;
extern  double   gd_lotsB               =0.01;              //Lot size for buy
extern  double   gd_lotsS               =0.01;              //Lot size for Sell
extern int gd_priceDistance=5;                           //customisableDistanceForPrice
extern int gd_slDistance=2;                              //customisableDistanceForStopLoss
extern int ei_magicNo=0;
extern double gd_perLotSize=2.0;
extern double gd_riPer=2.0;
int random=0;
int             gi_count=0 ;
string gs_operation = "Both_Buy_and_Sell";
int gi_flag;
int gi_ticket;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- 
    // _HPCS_EXPIRY_CHECK; 
    if(MoneyManagement==Fixed_amount)
    {
        gd_lotsB=gd_lotsB;
        gd_lotsS=gd_lotsS;
    }
    else if(MoneyManagement==Percentage_of_account)
    {
        gd_lotsB=(gd_perLotSize/100)*AccountBalance();
        if(gd_lotsB>8)
            gd_lotsB=8;
        if(gd_lotsB<0.01)
            gd_lotsB=0.01;
        
        gd_lotsS=(gd_perLotSize/100)*AccountBalance();
        if(gd_lotsS>8)
            gd_lotsS=8;
        if(gd_lotsS<0.01)
            gd_lotsS=0.01;    
        
    }
    else if(MoneyManagement==Lot_using_risk)
    {
        gd_lotsB=CalculateLotUsingRiskPercentage(gd_riPer,OP_BUYSTOP);
        gd_lotsS=CalculateLotUsingRiskPercentage(gd_riPer,OP_SELLSTOP);
    }  
    c=0;
    gdt_prev=Time[0];
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
        //  _HPCS_EXPIRY_CHECK;
         if(isNewSession())
         {
            gs_operation=EnumToString(type);  
            if(ge_operation==Pivot ||  ge_operation==MA_and_Pivot || ge_operation==MACD_and_Pivot || ge_operation==MACD_and_MA_and_Pivot)
             {
                  ++c;
             }
         }

         if(isNewBar())
         {
            if(c>0)
            {
                  if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMax(Open[1],Close[1]))
                  {      
                         gs_operation = "Buy";
                  }
                  else
                  {
                          gs_operation ="Sell";
                  }
            }       
            if(gi_flag==0)
            {      
                if(EnumToString(type)==gs_operation)
                {    
                     if(EnumToString(type)=="Buy")
                     {
                           if(fb_indicatorBuy(ge_operation))
                           {
                                 
                                 gi_ticket = PlacePendingOrder(OP_BUYLIMIT,gd_lotsB,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Buy Pending");
                                 if(gi_ticket<0)
                                 {
                                          Print("Order Failed ",GetLastError());
                                 }
                                 gi_flag=1;
                          } 
                     } 
                     else if(EnumToString(type)=="Sell")
                     {
                            if(fb_indicatorSell(ge_operation))
                            {
                                 gi_ticket =PlacePendingOrder(OP_SELLSTOP,gd_lotsS,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"sell Pending");
                                 if(gi_ticket<0)
                                 {
                                          Print("Order Failed ",GetLastError());
                                 }
                                 gi_flag=1;
                           } 
                    }
                    else if(EnumToString(type)=="Both_Buy_and_Sell" || EnumToString(type)=="According_to_signal") 
                    {
                         if(fb_indicatorBuy(ge_operation))
                           {
                                 gi_ticket = PlacePendingOrder(OP_BUYSTOP,gd_lotsB,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Buy Pending");
                                 if(gi_ticket<0)
                                 {
                                          Print("Order Failed ",GetLastError());
                                 }
                                 gi_flag=1;
                          } 
                          else  if(fb_indicatorSell(ge_operation))
                          {
                                 gi_ticket = PlacePendingOrder(OP_SELLLIMIT,gd_lotsS,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Sell Pending");
                                  if(gi_ticket<0)
                                 {
                                          Print("Order Failed ",GetLastError());
                                 }
                                 gi_flag=1;
                           } 
                   }
               }
                          
          }
          else
          {
               if(OrderSelect(gi_ticket,SELECT_BY_TICKET))
               {
                     
                        if(OrderCloseTime())
                        {
                           if(random != choice)
                           {
                               if(OrderProfit()>=0)
                               {
                                      random=0;
                               }
                               else
                               {
                                    random++;
                               }
                               
                                     if(EnumToString(type)==gs_operation )
                                     {    if(EnumToString(type)=="Buy")
                                          {
                                                if(fb_indicatorBuy(ge_operation))
                                                {
                                                      gi_ticket =PlacePendingOrder(OP_BUYSTOP,gd_lotsB,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Buy Pending");
                                                       if(gi_ticket<0)
                                                      {
                                                               Print("Order Failed ",GetLastError());
                                                      }
                                                      gi_flag=1;
                                               } 
                                          } 
                                          else if(EnumToString(type)=="Sell")
                                          {
                                                 if(fb_indicatorSell(ge_operation))
                                                 {
                                                      gi_ticket = PlacePendingOrder(OP_SELLSTOP,gd_lotsS,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Sell Pending");
                                                      if(gi_ticket<0)
                                                      {
                                                               Print("Order Failed ",GetLastError());
                                                      }
                                                      gi_flag=1;
                                                } 
                                         }
                                         else if(EnumToString(type)=="Both_Buy_and_Sell" || EnumToString(type)=="According_to_signal") 
                                            {
                                                 if(fb_indicatorBuy(ge_operation))
                                                   {
                                                         gi_ticket = PlacePendingOrder(OP_BUYSTOP,gd_lotsB,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Buy Pending");
                                                         if(gi_ticket<0)
                                                         {
                                                                  Print("Order Failed ",GetLastError());
                                                         }
                                                         gi_flag=1;
                                                  } 
                                                  else  if(fb_indicatorSell(ge_operation))
                                                  {
                                                         gi_ticket = PlacePendingOrder(OP_SELLLIMIT,gd_lotsS,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Sell Pending");
                                                          if(gi_ticket<0)
                                                         {
                                                                  Print("Order Failed ",GetLastError());
                                                         }
                                                         gi_flag=1;
                                                   } 
                                           }
                                    }
                              
                            }
                            else
                            {
                                    if(fb_indicatorBuy(ge_operation) || fb_indicatorSell(ge_operation))
                                    {
                                          random=0;
                                    }
                            }
                            
                              
                               
                        }
                        if(OrderType()==OP_BUY || OrderType()== OP_SELL)
                        {
                            TrailingStop(gd_slDistance);
                            if(EnumToString(type)==gs_operation )
                            {    if(EnumToString(type)=="Buy")
                                 {
                                       if(fb_indicatorBuy(ge_operation))
                                       {
                                             Print("Order ");
                                             gi_ticket =PlacePendingOrder(OP_BUYLIMIT,gd_lotsB,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Buy Pending");
                                             if(gi_ticket<0)
                                             {
                                                      Print("Order Failed ",GetLastError());
                                             }
                                             gi_flag=1;
                                      } 
                                 } 
                                 else if(EnumToString(type)=="Sell")
                                 {
                                        if(fb_indicatorSell(ge_operation))
                                        {
                                             gi_ticket =PlacePendingOrder(OP_SELLLIMIT,gd_lotsS,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Sell Pending");
                                             if(gi_ticket<0)
                                             {
                                                      Print("Order Failed ",GetLastError());
                                             }
                                             gi_flag=1;
                                       } 
                                }
                                   else if(EnumToString(type)=="Both_Buy_and_Sell" || EnumToString(type)=="According_to_signal") 
                                   {
                                        if(fb_indicatorBuy(ge_operation))
                                          {
                                                gi_ticket = PlacePendingOrder(OP_BUYSTOP,gd_lotsB,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Buy Pending");
                                                if(gi_ticket<0)
                                                {
                                                         Print("Order Failed ",GetLastError());
                                                }
                                                gi_flag=1;
                                         } 
                                         else  if(fb_indicatorSell(ge_operation))
                                         {
                                                gi_ticket = PlacePendingOrder(OP_SELLLIMIT,gd_lotsS,gd_priceDistance,gd_slDistance,id_tp,gi_slp,ei_magicNo,0,"Sell Pending");
                                                 if(gi_ticket<0)
                                                {
                                                         Print("Order Failed ",GetLastError());
                                                }
                                                gi_flag=1;
                                          } 
                                  }
                           }
                     }
                     else
                     {
                           gi_count++;
                           if(gi_count==gi_barallowed)
                           {
                                  if(OrderCloseTime())
                                  {
                                          
                                  }
                                  else if(!OrderDelete(OrderTicket(),clrAqua))
                                  {
                                          Print("Order Not Deleted ",GetLastError());
                                  }
                                  gi_count=0;
                           }
                     }
                    
             }    
          
          
          }
      } 
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//---For New Session---
bool isNewSession()
{
      if(TimeMinute(TimeCurrent())==0 && TimeHour(TimeCurrent())==0 && TimeSeconds(TimeCurrent())==0)
           return true;
       else
           return false;
 }
 //---for New Candle---
bool isNewBar()
{
         if(gdt_prev != Time[0])
         {
                  gdt_prev=Time[0];
                  return true;
         }
         return false;
}
//---Indicator Signal for Buy---
bool fb_indicatorBuy(ge_indicator lb_operation)
{
     
      switch(lb_operation)
      {
           case Pivot : if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMin(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMax(Open[2],Close[2]))
                            return true;
           case MACD  : if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)>gi_pos && iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)<gi_pos)
                             return true;
                        else if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)>gi_neg &&
                                 iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)<gi_neg)
                                    return true;
           case MA : if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                     {
                        if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                        {
                            return true;
                        }   
                    }
           case MA_and_MACD : if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)>gi_pos && iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)<gi_pos)
                              {     if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                     {
                                       if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                       {
                                           return true;
                                       }   
                                   }   
                              }
                              else if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)>gi_neg &&
                                 iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)<gi_neg)
                              {  if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                 {
                                    if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                    {
                                        return true;
                                    }   
                                } 
                             }
          case MA_and_Pivot :if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMin(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMax(Open[2],Close[2]))
                             {
                                 if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                 {
                                    if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                    {
                                        return true;
                                    }   
                                }
                             }
          case MACD_and_Pivot : if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)>gi_pos && iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)<gi_pos)
                                     if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMin(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMax(Open[2],Close[2]))
                                     {        return true;
                                     }
                                 else if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)>gi_neg &&
                                                iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)<gi_neg)
                                     if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMin(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMax(Open[2],Close[2]))
                                     {            
                                                   return true;
                                   
                                     }
         case MACD_and_MA_and_Pivot :if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMin(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMax(Open[2],Close[2]))
                                     {
                                          if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)>gi_pos && iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)<gi_pos)
                                          {     if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                                 {
                                                   if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                                   {
                                                       return true;
                                                   }   
                                               }   
                                          }
                                          else if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)>gi_neg &&
                                             iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)<gi_neg)
                                          {  if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                             {
                                                if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                                {
                                                    return true;
                                                }   
                                            } 
                                         }
                                     }
      }
      return false;
}
//---Indicator Signal For Sell                  
bool fb_indicatorSell(ge_indicator lb_operation)
{
     
      switch(lb_operation)
      {
           case Pivot : if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMax(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMin(Open[2],Close[2]))
                            return true;
           case MACD  : if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)<gi_pos && 
                              iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)>gi_pos)
                               return true;
                        else if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)<gi_neg &&
                                 iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)>gi_neg)
                                    return true;
           case MA : if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                     {
                        if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                        {
                            return true;
                        }   
                    }
           case MA_and_MACD : if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)<gi_pos && 
                                 iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)>gi_pos)
                              {     if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                     {
                                       if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                       {
                                           return true;
                                       }   
                                   }   
                              }
                              else if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)<gi_neg &&
                                 iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)>gi_neg)
                              {  if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                 {
                                    if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                    {
                                        return true;
                                    }   
                                } 
                             }
          case MA_and_Pivot :if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMax(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMin(Open[2],Close[2]))
                             {
                                 if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                 {
                                    if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                    {
                                        return true;
                                    }   
                                }
                             }
          case MACD_and_Pivot :if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMax(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMin(Open[2],Close[2]))
                                {
                                       if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)<gi_pos &&
                                           iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)>gi_pos)
                                             return true;
                                       else if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)<gi_neg &&
                                                iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)>gi_neg)
                                                   return true;
                                   
                               }
         case MACD_and_MA_and_Pivot :if(iCustom(Symbol(),0,"All Pivot Points",0,1)>MathMax(Open[1],Close[1]) && iCustom(Symbol(),0,"All Pivot Points",0,2)<MathMin(Open[2],Close[2]))
                                      {
                                          if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)<gi_pos &&
                                              iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)>gi_pos)
                                          {     if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                                 {
                                                   if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                                   {
                                                       return true;
                                                   }   
                                               }   
                                          }
                                          else if(iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,0)<gi_neg &&
                                             iMACD(Symbol(),Period(),gi_fastema,gi_slowema,gi_period,PRICE_CLOSE,MODE_MAIN,1)>gi_neg)
                                          {  if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,0)<iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,0))
                                             {
                                                if(iMA(Symbol(),Period(),gi_fmaPeriod,0,MODE_SMA,PRICE_MEDIAN,1)>iMA(Symbol(),Period(),gi_smaPeriod,0,MODE_SMA,PRICE_MEDIAN,1))
                                                {
                                                    return true;
                                                }   
                                            } 
                                         }
                                     }
      }
      return false;
      
}
//---Function For Trailing Stop---
void TrailingStop(double _TrailStop_IN_POINT, double _TrailingStopStart = 0 ,double _TrailingStopStep  = 0 , int _MagicNumber = 0)
 {
   int total = OrdersTotal();
   int _Stop_level = (int)MarketInfo(NULL,MODE_STOPLEVEL) ;
   double new_sl=0;  
   for(int i =0; i < total; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) == true)
      {
         if(OrderMagicNumber() == _MagicNumber && OrderSymbol() == Symbol())
         {
            if(OrderType() == OP_SELL)
            {
               if(_TrailStop_IN_POINT > 0 && OrderCloseTime() == 0)
               {         
                  if((Ask <= (OrderOpenPrice() - (_TrailingStopStart*Point )))||(_TrailingStopStart == 0 ))
                  {
                     if ((OrderStopLoss()-Ask) >= (Point*(_TrailStop_IN_POINT+_TrailingStopStep))|| OrderStopLoss()==0)
                     {
                        new_sl=NormalizeDouble(Bid+(Point*_TrailStop_IN_POINT),Digits);
                        if (new_sl >= Ask + _Stop_level*Point)
                        {
                           
                        }
                        else
                        {
                           new_sl = Ask + _Stop_level*Point ;         
                        }
                        new_sl=NormalizeDouble(new_sl,Digits);
                        if(new_sl<OrderStopLoss())
                        {
                           if(!OrderModify(OrderTicket(),OrderOpenPrice(),new_sl,OrderTakeProfit(),0,clrNONE))
                           {
                              Print("Sell Modify _Error #",GetLastError());
                           }
                        }                        
                     }
                  }
               }
            }
            else if(OrderType() == OP_BUY)
            {
               if(_TrailStop_IN_POINT > 0 && OrderCloseTime() == 0)
               {
                  if((Bid >= (OrderOpenPrice() + (_TrailingStopStart*Point)))||(_TrailingStopStart == 0 ))
                  {
                     if((Bid -OrderStopLoss()) >= (Point*(_TrailStop_IN_POINT+_TrailingStopStep))|| OrderStopLoss()==0)
                     {  
                        new_sl=NormalizeDouble(Ask-(Point*_TrailStop_IN_POINT),Digits);
                        if (new_sl <= Bid - _Stop_level*Point)
                        {
                           
                        }
                        else
                        {
                           new_sl = Bid - _Stop_level*Point ;         
                        }
                        new_sl=NormalizeDouble(new_sl,Digits);
                        if(new_sl>OrderStopLoss())
                        {
                           if(!OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(),0,clrNONE))
                           {
                               Print("Buy Modify _Error #",GetLastError());
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}       
int _factor=10; 
//---Function For Placing Pending Orders---              
int PlacePendingOrder( int      _OP,
                       double   _Lots,
                       int      _pipsTrgrPrcOfst,  // pending order to market order triggering price
                       int      _SLinPips       = 0,
                       int      _TPinPips       = 0,
                       int      _SlippageInPips = 10,
                       int      _MagicNumber    = 0,
                       datetime expiry          = 0,
                       string   _Comment        = "PO_HPCS" )
{
   //
   // Error code, printed in Experts log by this function for de-bugging:
   // E1( GetLastError() ) : [ERROR # _Error] Placing pending order failed
   //
   int rtrn_Ticket = -1,
       _StopLevel  = (int)MarketInfo( NULL, MODE_STOPLEVEL );
   //
   double _priceSL  = 0,
          _priceTP  = 0,
          _priceTrgr = 0;
   
   if( _OP == OP_BUYLIMIT )
   {
      _priceTrgr = Low[1] - _pipsTrgrPrcOfst * Point * _factor;
      if( _priceTrgr <= ( Low[1] - ( _StopLevel * Point ) ) )
      { // Refer: book.mql4.com/appendix/limits 
      }
      else
      {
         Alert( "Buy Limit Order Open Price is violating the minimum stop-level distance" );
         return( -1 );
      }
      if( _SLinPips == 0 )
      {
         _priceSL = 0;
      }
      else 
      {
         _priceSL = _priceTrgr - ( _SLinPips * Point * _factor );
         if( _priceSL <= ( _priceTrgr - ( _StopLevel * Point ) ) )
         { // Refer: book.mql4.com/appendix/limits 
         }
         else
         {
            _priceSL = _priceTrgr - ( _StopLevel * Point );         
         }
      }
      if( _TPinPips == 0 )
      {
         _priceTP = 0;
      }
      else 
      {
         _priceTP = _priceTrgr + ( _TPinPips * Point * _factor );
         if( _priceTP >= ( _priceTrgr + ( _StopLevel * Point ) ) )
         { // Refer: book.mql4.com/appendix/limits 
         }
         else
         {
            _priceTP = _priceTrgr + ( _StopLevel * Point );         
         }
      }
   } 
   else if( _OP == OP_BUYSTOP )
   {
      _priceTrgr = High[1] + ( _pipsTrgrPrcOfst * Point * _factor );
      if( _priceTrgr >= ( High[1] + ( _StopLevel * Point ) ) )
      { // Refer: book.mql4.com/appendix/limits 
      }
      else
      {
         Alert( "Buy Stop Order Open Price is violating the minimum stop-level distance" );
         return( -1 );
      }
      if( _SLinPips == 0 )
      {
         _priceSL = 0;
      }
      else 
      {
         _priceSL = _priceTrgr - ( _SLinPips * Point * _factor );
         if( _priceSL <= ( _priceTrgr - ( _StopLevel * Point ) ) )
         { // Refer: book.mql4.com/appendix/limits 
         }
         else
         {
            _priceSL = _priceTrgr - ( _StopLevel * Point );         
         }
      }
      if( _TPinPips == 0 )
      {
         _priceTP = 0;
      }
      else 
      {
         _priceTP = _priceTrgr + ( _TPinPips * Point * _factor );
         if( _priceTP >= ( _priceTrgr + ( _StopLevel * Point ) ) )
         { // Refer: book.mql4.com/appendix/limits 
         }
         else
         {
            _priceTP = _priceTrgr + ( _StopLevel * Point );         
         }
      }
   } 
   else if( _OP == OP_SELLLIMIT )
   {
      _priceTrgr = High[1] + ( _pipsTrgrPrcOfst * Point * _factor );
      if( _priceTrgr >= ( High[1] + ( _StopLevel * Point ) ) )
      { // Refer: book.mql4.com/appendix/limits 
      }
      else
      {
         Alert( "Sell Limit Order Open Price is violating the minimum stop-level distance" );
         return( -1 );
      }
      if( _SLinPips == 0 )
      {
         _priceSL = 0;
      }
      else
      {
         _priceSL = _priceTrgr + ( _SLinPips * Point * _factor );
         if( _priceSL >= ( _priceTrgr + ( _StopLevel * Point ) ) )
         { // Refer: book.mql4.com/appendix/limits 
         }
         else
         {
            _priceSL = _priceTrgr + ( _StopLevel * Point );
         }
      }
      if( _TPinPips == 0 )
      {
         _priceTP = 0;
      }
      else
      {
         _priceTP = _priceTrgr - ( _TPinPips * Point * _factor );
         if( _priceTP <= ( _priceTrgr - ( _StopLevel * Point ) ) )
         { // Refer: book.mql4.com/appendix/limits 
         }
         else
         {
            _priceTP = _priceTrgr - ( _StopLevel * Point );
         }
      }
   } 
   else if( _OP == OP_SELLSTOP )
   {
      _priceTrgr = Low[1] - ( _pipsTrgrPrcOfst * Point * _factor );
      if( _priceTrgr <= ( Low[1] - ( _StopLevel * Point ) ) )
      { // Refer: book.mql4.com/appendix/limits 
      }
      else
      {
         Alert( "Sell Stop Order Open Price is violating the minimum stop-level distance" );
         return( -1 );
      }
      if( _SLinPips == 0 )
      {
         _priceSL = 0;
      }
      else
      {
         _priceSL = _priceTrgr + ( _SLinPips * Point * _factor );
         if( _priceSL >= ( _priceTrgr + ( _StopLevel * Point ) ) )
         { // Refer: book.mql4.com/appendix/limits 
         }
         else
         {
            _priceSL = _priceTrgr + ( _StopLevel * Point );
         }
      }
      if( _TPinPips == 0 )
      {
         _priceTP = 0;
      }
      else
      {
         _priceTP = _priceTrgr - ( _TPinPips * Point * _factor );
         if( _priceTP <= ( _priceTrgr - ( _StopLevel * Point ) ) )
         { // Refer: book.mql4.com/appendix/limits 
         }
         else
         {
            _priceTP = _priceTrgr - ( _StopLevel * Point );
         }
      }
   }
   
   // normalize all price values to digits
   _priceTrgr = NormalizeDouble( _priceTrgr, _Digits );
   _priceSL   = NormalizeDouble( _priceSL, _Digits );
   _priceTP   = NormalizeDouble( _priceTP, _Digits );
   
   // ensure lot is within allowed limits
   func_EnsureLotWithinAllowedLimits( _Lots );
   
   // place a pending order
   switch( _OP )
   {
      case OP_BUYLIMIT  : rtrn_Ticket = OrderSend( Symbol(), OP_BUYLIMIT, _Lots, _priceTrgr, _SlippageInPips, _priceSL, _priceTP, _Comment, _MagicNumber, expiry, clrBlueViolet );
                          break;
      case OP_SELLLIMIT : rtrn_Ticket = OrderSend( Symbol(), OP_SELLLIMIT, _Lots, _priceTrgr, _SlippageInPips, _priceSL, _priceTP, _Comment, _MagicNumber, expiry, clrGold );
                          break;
      case OP_BUYSTOP   : rtrn_Ticket = OrderSend( Symbol(), OP_BUYSTOP, _Lots, _priceTrgr, _SlippageInPips, _priceSL, _priceTP, _Comment, _MagicNumber, expiry, clrBlueViolet );
                          break;
      case OP_SELLSTOP  : rtrn_Ticket = OrderSend( Symbol(), OP_SELLSTOP, _Lots, _priceTrgr, _SlippageInPips, _priceSL, _priceTP, _Comment, _MagicNumber, expiry, clrGold );                                                 
                          break;
      default           : Alert( "Wrong Pending Order type" );
                          return( rtrn_Ticket );
   }
   
   // message error code for de-bugging, if order is not placed successfully
   if( rtrn_Ticket == -1 )
   {
      Print( TimeToString( TimeCurrent(), TIME_DATE|TIME_SECONDS ) + " " 
           + __FUNCTION__ + ": E1(" + IntegerToString( GetLastError() ) + ")" );   
   }
   //
   return( rtrn_Ticket );
}              
//---Function For Lot using RiskPercentage-- 
double CalculateLotUsingRiskPercentage( double _dRiskPercent,
                                        int    _iOrderType,
                                        string _sSymbol = NULL ) {
// calculate lot using trade(%) for given pair and order type
    double rd_Lot = 0,
           ld_PriceEntry = 0;
    int _digit = (int)MarketInfo( _sSymbol, MODE_DIGITS );
    //
    // get order's entry price, as per order type
    if( _iOrderType == OP_BUY ) {
      ld_PriceEntry = MarketInfo( _sSymbol, MODE_ASK );
    }
    else if( _iOrderType == OP_SELL ) {
      ld_PriceEntry = MarketInfo( _sSymbol, MODE_BID );
    }
   // rd_Lot  = ((AccountFreeMargin()*AccountLeverage()*_dRiskPercent)/(((Bid)*MarketInfo(_sSymbol,MODE_LOTSIZE)*100))); 
   //rd_Lot = ( ( AccountFreeMargin() * AccountLeverage() * _dRiskPercent )/( ld_PriceEntry *MathPow( 10, _digit ) * 100 ) );
   rd_Lot = ( ( AccountEquity() * _dRiskPercent )/( ld_PriceEntry *MathPow( 10, _digit ) * 100 ) );
   // ensure lot is within allowed limits
   func_EnsureLotWithinAllowedLimits( rd_Lot, _sSymbol );
   return( rd_Lot );      
}
//----Function for Lots in range---
void func_EnsureLotWithinAllowedLimits( double& chng_Lot,
                                        string _namePair = NULL) 
{
   string lcl_MsgCode = NULL;
   double lcl_MinPermittedLot = MarketInfo( _namePair, MODE_MINLOT ),
          lcl_MaxPermittedLot = MarketInfo( _namePair, MODE_MAXLOT ),
          lcl_MinPermittedLotStep = MarketInfo( _namePair, MODE_LOTSTEP );
   //
   int _LotDigits = 4;
   double micro_lot = 0.01,mini_lot =0.1,lot1=1;
   
   if(chng_Lot < lcl_MinPermittedLot) 
   { 
      // lot must not be below the minimum allowed limit
      Print("[INFO]: Requested Lot(",DoubleToString(chng_Lot,5),") < Minimum allowed lot(",DoubleToString(lcl_MinPermittedLot,5),")");
      Print("[INFO]: Updated requested Lot to the Minimum allowed lot to place order successfully");
      chng_Lot = lcl_MinPermittedLot;
   } 
   else if(chng_Lot > lcl_MaxPermittedLot) 
   { 
      // lot must not be above the maximum allowed limit
      Print("[INFO]: Requested Lot(",DoubleToString(chng_Lot,5),") > Maximum allowed lot(",DoubleToString(lcl_MaxPermittedLot,5),")");
      Print("[INFO]: Updated requested Lot to the Maximum allowed lot to place order successfully");
      chng_Lot = lcl_MaxPermittedLot;
   }
   double _LotMicro = 0.01, // micro lots
          _LotMini  = 0.10, // mini lots
          _LotNrml  = 1.00;
   if( lcl_MinPermittedLot == _LotMicro )
      _LotDigits = 2;
   else if(lcl_MinPermittedLot == _LotMini )
      _LotDigits = 1;
   else if(lcl_MinPermittedLot == _LotNrml )
      _LotDigits = 0;
   chng_Lot = NormalizeDouble( chng_Lot, _LotDigits);
}                
                
     


        
                 
                
                
     


        
 