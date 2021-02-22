//+------------------------------------------------------------------+
//|                                              BackTestChuffle.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

double nyValues[2];
double nyLow = 0;
double nyHigh = 0;
double buySlip1 = 0;
double buySlip2 = 0;
double sellSlip1 = 0;
double sellSlip2 = 0;         

void OnTick()
  {
//---
   Print("The NyHigh is: ",nyHigh);
   Print("The NyLow is: ", nyLow);
   if(OnionTags(nyValues)&& (nyHigh==0)&& (nyLow==0))
   {
        
      nyHigh = nyValues[0];
      nyLow = nyValues[1];
      buySlip1 = (nyHigh + 2);
      buySlip2 = (nyHigh - 2);
      sellSlip1 = (nyLow + 2);
      sellSlip2 = (nyLow - 2);     
      
      Print("NY LOW: ", nyLow);
      Print("NY HIGH: ", nyHigh);
   }
   if((OrdersTotal() < 1)&&(nyHigh> 0)&&(nyLow>0))
   {  
      double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
      double PriceBid = MarketInfo(Symbol(), MODE_BID);
      if((buySlip1 >= PriceAsk)&& (buySlip2 <= PriceAsk))
      {
         double nyHighTp = (nyHigh + 300);  
         int orderIDBuy = OrderSend(NULL,OP_BUY,0.05,nyHigh,10,nyLow,nyHighTp);
      }       
      if((sellSlip1 >= PriceBid)&& (sellSlip2 <= PriceBid))
      {
         double nyLowTp = (nyLow - 300);
         int orderIDSell = OrderSend(NULL,OP_SELL,0.05,nyLow,10,nyHigh,nyLowTp);  
      }
   }
   if(OrdersTotal() == 1)
   {
      ModifyOrder();
   }
   
   
   datetime time=TimeLocal();
   string HoursAndMinutes=TimeToString(time,TIME_MINUTES);


   if(StringSubstr(HoursAndMinutes,0,5)=="17:00")
   {
      if(OrdersTotal() > 0)
      {
         int pipGainer = 25;     
         if(OrderType()==0)
         {
            double TrailingStopPriceBuy = (nyHigh + pipGainer);
            OrderClose(OrderTicket(),OrderLots(),TrailingStopPriceBuy,4,Blue);
            Print("Order closing at price: ", TrailingStopPriceBuy);
         }
         if(OrderType()==1)
         {
            double TrailingStopPriceSell = (nyLow - pipGainer);
            OrderClose(OrderTicket(),OrderLots(),TrailingStopPriceSell,1,Yellow);
            Print("Order closing at price: ", TrailingStopPriceSell);
         }
      }
         
       nyValues[0]=0;
       nyValues[1]=0;
       nyLow = 0;
       nyHigh = 0; 
   }
  }
//+------------------------------------------------------------------+
bool OnionTags(double& NYValues[])
   {
       Print("");
       //Initialize variables
       int WindowSizeInBars=2;        //number of candles to scan
       datetime time=TimeLocal();
       double nyHighest=High[0];
       double nyLowest=Low[0];
       string HoursAndMinutes=TimeToString(time,TIME_MINUTES);
       bool running = True;
     
          //Scan the 12 candles and update values of highest and lowest

         if(StringSubstr(HoursAndMinutes,0,5)=="08:00")
         {
           for(int i=0; i<=WindowSizeInBars; i++)
                {
                     if(High[i]>nyHighest) nyHighest=High[i];
                     if(Low[i]<nyLowest) nyLowest=Low[i];
                }         
   
            NYValues[0] = nyHighest;
            NYValues[1] = nyLowest;
            return True;
            //return values;
         }
         else
         {
            Print("No Data");
   
         }

            
         return False;
   }
   
void ModifyOrder()
{
   int pipGainer = 25;
   int pipGainer2 = 50;
   int pipGainer3 = 75;
   int pipGainer4 = 100;
   int pipGainer5 = 125;
   int pipGainer6 = 150;
   int pipGainer7 = 175;
   int pipGainer8 = 200;
   
   double stopLossBuy1 = (nyHigh + 1);
   double stopLossBuy2 = (OrderOpenPrice() + pipGainer);
   double stopLossBuy3 = (OrderOpenPrice() + pipGainer2);
   double stopLossBuy4 = (OrderOpenPrice() + pipGainer3);
   double stopLossBuy5 = (OrderOpenPrice() + pipGainer4);
   double stopLossBuy6 = (OrderOpenPrice() + pipGainer5);
   double stopLossBuy7 = (OrderOpenPrice() + pipGainer6);
   double stopLossBuy8 = (OrderOpenPrice() + pipGainer7);
   
   double stopLossSell1 = (nyLow - 1);
   double stopLossSell2 = (OrderOpenPrice() - pipGainer);
   double stopLossSell3 = (OrderOpenPrice() - pipGainer2);
   double stopLossSell4 = (OrderOpenPrice() - pipGainer3);
   double stopLossSell5 = (OrderOpenPrice() - pipGainer4);
   double stopLossSell6 = (OrderOpenPrice() - pipGainer5);
   double stopLossSell7 = (OrderOpenPrice() - pipGainer6);
   double stopLossSell8 = (OrderOpenPrice() - pipGainer7);

   OrderSelect(0, SELECT_BY_POS, MODE_TRADES); 
   if(OrderType()==OP_BUY)
   {
      if(OrderProfit() > pipGainer)
      { 
         double currentPriceBuy = MarketInfo(Symbol(),MODE_ASK);
         stopLossBuy1 = (OrderOpenPrice() + 1);
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
               OrderClose(OrderTicket(),0.03,TrailingStopPriceBuy,4,Blue);
               Print("Order closing at price: ", TrailingStopPriceBuy);  
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
         stopLossSell1 = (OrderOpenPrice() - 1);
         if((currentPriceSell <= OrderOpenPrice())&&(currentPriceSell >= stopLossSell2))   
         {  
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell1,OrderTakeProfit(),0,Yellow);
            if(!res)
            {           
               Print("Error in OrderModify Sell One. Error Code=", GetLastError());              
            }
            else
            {
               double TrailingStopPriceSell = (nyLow - pipGainer);
               OrderClose(OrderTicket(),0.03,TrailingStopPriceSell,1,Yellow);
               Print("Order closing at price: ", TrailingStopPriceSell);
            }
         } 
         if((currentPriceSell <= stopLossSell3)&&(currentPriceSell >= stopLossSell2))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell2,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Two. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell <= stopLossSell4)&&(currentPriceSell >= stopLossSell3))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell3,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Three. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell <= stopLossSell5)&&(currentPriceSell >= stopLossSell4))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell4,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Four. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell <= stopLossSell6)&&(currentPriceSell >= stopLossSell5))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell5,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Five. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell <= stopLossSell7)&&(currentPriceSell >= stopLossSell6))
         {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell6,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Six. Error Code=", GetLastError());              
               }
         }
         if((currentPriceSell <= stopLossSell8)&&(currentPriceSell >= stopLossSell7))
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
