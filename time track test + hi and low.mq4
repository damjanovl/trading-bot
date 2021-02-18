//+------------------------------------------------------------------+
//|                                 time track test + hi and low.mq4 |
//|                                                      CHICO ONION |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "CHICO ONION"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <NY_Chuffle_Functions.mqh>
double nyValues[2];
bool returnValue = False;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {
     Print("The Rico Shuffle has started. Sit back and enjoy the show. Goof.");
     while (!returnValue) 
   {
      returnValue = OnionTags(nyValues);
        
      double nyHigh = nyValues[0];
      double nyLow = nyValues[1];     
      
      Print("NY LOW: ", nyLow);
      Print("NY HIGH: ", nyHigh);
   }
       
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


datetime time=TimeLocal();
string HoursAndMinutes=TimeToString(time,TIME_MINUTES);
double nyHigh = nyValues[0];
double nyLow = nyValues[1];
bool running = True;

int pipGainer = 5;
int pipGainer2 = 10;
int pipGainer3 = 15;
int pipGainer4 = 100;
int pipGainer5 = 125;
int pipGainer6 = 150;
int pipGainer7 = 175;
int pipGainer8 = 200;

double stopLossBuy2 = (OrderOpenPrice() + pipGainer);
double stopLossBuy3 = (OrderOpenPrice() + pipGainer2);
double stopLossBuy4 = (OrderOpenPrice() + pipGainer3);
double stopLossBuy5 = (OrderOpenPrice() + pipGainer4);
double stopLossBuy6 = (OrderOpenPrice() + pipGainer5);
double stopLossBuy7 = (OrderOpenPrice() + pipGainer6);
double stopLossBuy8 = (OrderOpenPrice() + pipGainer7);

double stopLossSell2 = (OrderOpenPrice() - pipGainer);
double stopLossSell3 = (OrderOpenPrice() - pipGainer2);
double stopLossSell4 = (OrderOpenPrice() - pipGainer3);
double stopLossSell5 = (OrderOpenPrice() - pipGainer4);
double stopLossSell6 = (OrderOpenPrice() - pipGainer5);
double stopLossSell7 = (OrderOpenPrice() - pipGainer6);
double stopLossSell8 = (OrderOpenPrice() - pipGainer7);
double buySlip1 = (nyHigh + 1);
double buySlip2 = (nyHigh - 1);
double sellSlip1 = (nyLow + 1);
double sellSlip2 = (nyLow - 1);


while(running&& (OrdersTotal() < 1))//change this so it trades until you clinch profit (02.10.21)
{
   double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
   double PriceBid = MarketInfo(Symbol(), MODE_BID);
   if((buySlip1 >= PriceAsk)&& (buySlip2 <= PriceAsk))
   {
      double nyHighTp = (nyHigh + 300);  
      int orderIDBuy = OrderSend(NULL,OP_BUY,0.02,nyHigh,10,nyLow,nyHighTp);
   }       
   if((sellSlip1 >= PriceBid)&& (sellSlip2 <= PriceBid))
   {
      double nyLowTp = (nyLow - 300);
      int orderIDSell = OrderSend(NULL,OP_SELL,0.02,nyLow,10,nyHigh,nyLowTp);  
   }

}


if(OrdersTotal() == 1)
{
   running = False;
}


for(int i=0;i<OrdersTotal();i++)//if a trade hits SL to BE we do not want to trade after. (02.10.2021)
{
   OrderSelect(i, SELECT_BY_POS, MODE_TRADES); 
   if(OrderType()==OP_BUY)
   {
      if(OrderProfit() > pipGainer)
      { 
         double currentPriceBuy = MarketInfo(Symbol(),MODE_ASK);
         double stopLossBuy1 = (OrderOpenPrice() + 1);
         double currentPriceSlip = (currentPriceBuy + 2);
         double currentPriceSlip2 = (currentPriceBuy - 2);
         //double TrailingStopPriceBuy1 = (nyHigh + pipGainer);
         if((currentPriceBuy >= OrderOpenPrice())&& (currentPriceBuy <= stopLossBuy2))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy1,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy One. Error Code=", GetLastError());
            }
            else
            {
               double TrailingStopPriceBuy = (nyHigh + pipGainer);
               OrderClose(OrderTicket(),0.01,TrailingStopPriceBuy,4,Blue);  
            }
         }
         if((currentPriceBuy >= stopLossBuy2)&&(currentPriceBuy <= stopLossBuy3))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy2,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Two. Error Code=", GetLastError());
               }
         }
         if((currentPriceBuy >= stopLossBuy3)&&(currentPriceBuy <= stopLossBuy4))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy3,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Three. Error Code=", GetLastError());
               }
         }
         if((currentPriceBuy >= stopLossBuy4)&&(currentPriceBuy <= stopLossBuy5))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy4,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Four. Error Code=", GetLastError());
               }
         }
         if((currentPriceBuy >= stopLossBuy5)&&(currentPriceBuy <= stopLossBuy6))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy5,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Five. Error Code=", GetLastError());
               }
         }
         if((currentPriceBuy >= stopLossBuy6)&&(currentPriceBuy <= stopLossBuy7))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy6,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Six. Error Code=", GetLastError());
               }
         }
         if((currentPriceBuy >= stopLossBuy7)&&(currentPriceBuy <= stopLossBuy8))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy7,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Seven. Error Code=", GetLastError());
               }
         }
         if(currentPriceBuy >= stopLossBuy8)
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy8,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Eight. Error Code=", GetLastError());
               }
         }

       }

   }
   if(OrderType()==OP_SELL)
   {
      if(OrderProfit() > pipGainer)
      {  
         double currentPriceSell = MarketInfo(Symbol(),MODE_BID);
         double stopLossSell1 = (OrderOpenPrice() - 1);
         if((currentPriceSell >= OrderOpenPrice())&&(currentPriceSell <= stopLossSell2))   
         {  
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell1,OrderTakeProfit(),0,Yellow);
            if(!res)
            {           
               Print("Error in OrderModify Sell One. Error Code=", GetLastError());              
            }
            else
            {
               double TrailingStopPriceSell = (nyLow - pipGainer);
               OrderClose(OrderTicket(),0.01,TrailingStopPriceSell,1,Yellow);
            }
         } 
         if((currentPriceSell >= stopLossSell2)&&(currentPriceSell <= stopLossSell3))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell2,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Two. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell >= stopLossSell3)&&(currentPriceSell <= stopLossSell4))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell3,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Three. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell >= stopLossSell4)&&(currentPriceSell <= stopLossSell5))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell4,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Four. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell >= stopLossSell5)&&(currentPriceSell <= stopLossSell6))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell5,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Five. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell >= stopLossSell6)&&(currentPriceSell <= stopLossSell7))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell6,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Six. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell >= stopLossSell7)&&(currentPriceSell <= stopLossSell8))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell7,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Seven. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell <= stopLossSell8)
         {
            Print("the stoplosssell8 is:", stopLossSell8);
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell8,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Eight. Error Code=", GetLastError());              
               }
         }
      }
    }
 }
if(StringSubstr(HoursAndMinutes,0,5)=="17:00")
      {
         ZeroMemory(nyValues[0]);
         ZeroMemory(nyValues[1]);
      }
}


