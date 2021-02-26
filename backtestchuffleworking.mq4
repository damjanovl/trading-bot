
double nyValues[2];
double nyLow = 0;
double nyHigh = 0;
double buySlip1 = 0;
double buySlip2 = 0;
double sellSlip1 = 0;
double sellSlip2 = 0;
double dailyLoss = 0;
int nyRange = 50;
int nySlippage = 1;

extern double DrawdownPercent = 4.5;     //e.g. for 2% drawdown

void OnTick()
  {
//---
   if(OnionTags(nyValues)&& (nyHigh==0)&& (nyLow==0))
   {       
      nyHigh = nyValues[0];
      nyLow = nyValues[1];
      buySlip1 = (nyHigh + nySlippage);
      buySlip2 = (nyHigh - nySlippage);
      sellSlip1 = (nyLow + nySlippage);
      sellSlip2 = (nyLow - nySlippage);     
      
      Print("NY LOW: ", nyLow);
      Print("NY HIGH: ", nyHigh);
   }
   
	
   if((OrdersTotal() < 1)&&(nyHigh> 0)&&(nyLow>0)&&((nyHigh-nyLow) < nyRange))
   {
      double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
      double PriceBid = MarketInfo(Symbol(), MODE_BID);
      if((buySlip1 >= PriceAsk)&& (buySlip2 <= PriceAsk))
      {
         double nyHighTp = (nyHigh + 200);  
         int orderIDBuy = OrderSend(NULL,OP_BUY,0.04,nyHigh,nySlippage,nyLow,nyHighTp);
      }       
      if((sellSlip1 >= PriceBid)&& (sellSlip2 <= PriceBid))
      {
         double nyLowTp = (nyLow - 200);
         int orderIDSell = OrderSend(NULL,OP_SELL,0.04,nyLow,nySlippage,nyHigh,nyLowTp);  
      }                 
   }
   
   if(OrdersTotal() == 1)
   {
      ModifyOrder();
   }
  
   
   if((1-AccountEquity()/AccountBalance())*100>NormalizeDouble(DrawdownPercent, 2))
   {
      CloseOpenOrders();
   }
   
   datetime time=TimeLocal();
   string HoursAndMinutes=TimeToString(time,TIME_MINUTES);

   if(StringSubstr(HoursAndMinutes,0,5)=="17:00")
   {
      if(OrdersTotal() > 0)
      {          
         if(OrderType()==0)
         {
            double currentPriceBuy = MarketInfo(Symbol(),MODE_ASK);
            OrderClose(OrderTicket(),OrderLots(),currentPriceBuy,nySlippage,Blue);
            Print("Order closing at price: ", currentPriceBuy);
         }
         if(OrderType()==1)
         {
            double currentPriceSell = MarketInfo(Symbol(),MODE_BID);
            OrderClose(OrderTicket(),OrderLots(),currentPriceSell,nySlippage,Yellow);
            Print("Order closing at price: ", currentPriceSell);
         }         
      }         
       nyValues[0]=0;
       nyValues[1]=0;
       nyLow = 0;
       nyHigh = 0;
       dailyLoss = 0;
   }
  }
//+------------------------------------------------------------------+
bool OnionTags(double& NYValues[])
   {
       //Initialize variables
       int WindowSizeInBars=12;        //number of candles to scan
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
   int pipGainer5 = 150;

   
   double stopLossBuy1 = (nyHigh + 1);
   double stopLossBuy2 = (OrderOpenPrice() + pipGainer);
   double stopLossBuy3 = (OrderOpenPrice() + pipGainer2);
   double stopLossBuy4 = (OrderOpenPrice() + pipGainer3);
   double stopLossBuy5 = (OrderOpenPrice() + pipGainer4);
   double stopLossBuy6 = (OrderOpenPrice() + pipGainer5);

   
   double stopLossSell1 = (nyLow - 1);
   double stopLossSell2 = (OrderOpenPrice() - pipGainer);
   double stopLossSell3 = (OrderOpenPrice() - pipGainer2);
   double stopLossSell4 = (OrderOpenPrice() - pipGainer3);
   double stopLossSell5 = (OrderOpenPrice() - pipGainer4);
   double stopLossSell6 = (OrderOpenPrice() - pipGainer5);

   OrderSelect(0, SELECT_BY_POS, MODE_TRADES); 
   bool res = False;
   if(OrderType()==0||2||3)
   {
      if(OrderProfit() > pipGainer)
      { 
         double currentPriceBuy = MarketInfo(Symbol(),MODE_ASK);
         //double TrailingStopPriceBuy1 = (nyHigh + pipGainer);
         if(currentPriceBuy ==(OrderOpenPrice() + pipGainer))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy1,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy One. Error Code=", GetLastError());
            }
            else
            {
               double TrailingStopPriceBuy = (nyHigh + pipGainer);
               OrderClose(OrderTicket(),0.01,TrailingStopPriceBuy,nySlippage,Blue);  
            }
         }
         if(currentPriceBuy ==(OrderOpenPrice() + pipGainer2))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy2,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy Two. Error Code=", GetLastError());
            }
         }
         if(currentPriceBuy ==(OrderOpenPrice() + pipGainer3))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy3,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Three. Error Code=", GetLastError());
               }
         }
         if(currentPriceBuy ==(OrderOpenPrice() + pipGainer4))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy4,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Four. Error Code=", GetLastError());
               }
         }
         if(currentPriceBuy ==(OrderOpenPrice() + pipGainer5))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy5,OrderTakeProfit(),0,Blue);
               if(!res)
               {
                  Print("Error in OrderModify Buy Five. Error Code=", GetLastError());
               }
         }

       }

   }
   if(OrderType()==1||4||5)
   {
      if(OrderProfit() > pipGainer)
      {  
         double currentPriceSell = MarketInfo(Symbol(),MODE_BID);
         if(currentPriceSell ==(OrderOpenPrice() - pipGainer))   
         {  
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell1,OrderTakeProfit(),0,Yellow);
            if(!res)
            {           
               Print("Error in OrderModify Sell One. Error Code=", GetLastError());              
            }
            else
            {
               double TrailingStopPriceSell = (nyLow - pipGainer);
               OrderClose(OrderTicket(),0.01,TrailingStopPriceSell,nySlippage,Yellow);
            }
         } 
         if(currentPriceSell ==(OrderOpenPrice() - pipGainer2))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell2,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Two. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell ==(OrderOpenPrice() - pipGainer3))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell3,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Three. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell ==(OrderOpenPrice() - pipGainer4))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell4,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Four. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell ==(OrderOpenPrice() - pipGainer5))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell5,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Five. Error Code=", GetLastError());              
               }
         }
      }
    }
}



void CloseOpenOrders()
{
   bool result=false;
   for(int i=0;i<OrdersTotal();i++)
   {
      OrderSelect(i,SELECT_BY_POS);
      if(OrderType()== 1)
      {
         double currentPriceBuy = MarketInfo(Symbol(),MODE_ASK);
         result=OrderClose(OrderTicket(),OrderLots(),currentPriceBuy,nySlippage,Blue);
         Print("Order closing at price: ", currentPriceBuy);
      }
      if(OrderType()== 2)
      {
         double currentPriceSell = MarketInfo(Symbol(),MODE_BID);
         result=OrderClose(OrderTicket(),OrderLots(),currentPriceSell,nySlippage,Blue);
         Print("Order closing at price: ", currentPriceSell);
      }
      if(!result)Print("CloseOpenOrders failed with error#",GetLastError());
   }
}



