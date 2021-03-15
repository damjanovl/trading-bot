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

extern double DrawdownPercent = 3.5;     //e.g. for 2% drawdown

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
   
	
   if((OrdersTotal() < 1)&&(nyHigh> 0)&&(nyLow>0)&&((nyHigh-nyLow) < nyRange)&&(CheckTodaysOrders() < 2))
   {
      double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
      double PriceBid = MarketInfo(Symbol(), MODE_BID);
      if((buySlip1 >= PriceAsk)&& (buySlip2 <= PriceAsk))
      {
         double nyHighTp = (nyHigh + 250);  
         int orderIDBuy = OrderSend(NULL,OP_BUY,0.05,nyHigh,nySlippage,nyLow,nyHighTp);
      }       
      if((sellSlip1 >= PriceBid)&& (sellSlip2 <= PriceBid))
      {
         double nyLowTp = (nyLow - 250);
         int orderIDSell = OrderSend(NULL,OP_SELL,0.05,nyLow,nySlippage,nyHigh,nyLowTp);  
      }                 
   }
   
   if(OrdersTotal() == 1)
   {
      ModifyOrder();
   }
  
   
   if((1-AccountEquity()/AccountBalance())*100>NormalizeDouble(DrawdownPercent, 2))
   {
      CloseOpenOrders();
      nyLow = 0;
      nyHigh = 0;
   }
   
   datetime time=TimeLocal();
   string HoursAndMinutes=TimeToString(time,TIME_MINUTES);

   if(StringSubstr(HoursAndMinutes,0,5)=="23:59")
   {
      if(OrdersTotal() > 0)
      {          
        CloseOpenOrders();         
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
                    
         return False;
   }
   
void ModifyOrder()
{
   int nyModify = 2;
   
   int pipGainer = 25;
   int pipGainer2 = 50;
   int pipGainer3 = 100;
   int pipGainer4 = 150;
   int pipGainer5 = 200;

   
   double stopLossBuy1 = NormalizeDouble((nyHigh + 1),6);
   double stopLossBuy2 = NormalizeDouble((nyHigh + pipGainer),6);
   double stopLossBuy3 = NormalizeDouble((nyHigh + pipGainer2),6);
   double stopLossBuy4 = NormalizeDouble((nyHigh + pipGainer3),6);
   double stopLossBuy5 = NormalizeDouble((nyHigh + pipGainer4),6);
   double stopLossBuy6 = NormalizeDouble((nyHigh + pipGainer5),6);

   
   double stopLossSell1 = NormalizeDouble((nyLow - 1),6);
   double stopLossSell2 = NormalizeDouble((nyLow - pipGainer),6);
   double stopLossSell3 = NormalizeDouble((nyLow - pipGainer2),6);
   double stopLossSell4 = NormalizeDouble((nyLow - pipGainer3),6);
   double stopLossSell5 = NormalizeDouble((nyLow - pipGainer4),6);
   double stopLossSell6 = NormalizeDouble((nyLow - pipGainer5),6);

   OrderSelect(0, SELECT_BY_POS, MODE_TRADES); 
   bool res = False;
   if(OrderType()==0)
   {
      if(OrderProfit() > pipGainer)
      { 
         double currentPriceBuy = MarketInfo(Symbol(),MODE_ASK);
         //double TrailingStopPriceBuy1 = (nyHigh + pipGainer);
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer + nyModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer - nyModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy1,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy One. Error Code=", GetLastError());
            }
            else
            {
               ClosePartialOrders(); 
            }
         }
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer2 + nyModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer2 - nyModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy2,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy Two. Error Code=", GetLastError());
            }
         }
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer3 + nyModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer3 - nyModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy3,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy Three. Error Code=", GetLastError());
            }
         }
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer4 + nyModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer4 - nyModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy4,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy Four. Error Code=", GetLastError());
            }
         }
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer5 + nyModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer5 - nyModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy5,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy Five. Error Code=", GetLastError());
            }
         }

       }

   }
   if(OrderType()==1)
   {
      if(OrderProfit() > pipGainer)
      {  
         double currentPriceSell = MarketInfo(Symbol(),MODE_BID);
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer + nyModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer - nyModify))   
         {  
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell1,OrderTakeProfit(),0,Yellow);
            if(!res)
            {           
               Print("Error in OrderModify Sell One. Error Code=", GetLastError());              
            }
            else
            {
               ClosePartialOrders();
            }
         } 
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer2 + nyModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer2 - nyModify))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell2,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Two. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer3 + nyModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer3 - nyModify))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell3,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Three. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer4 + nyModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer4 - nyModify))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell4,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Four. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer5 + nyModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer5 - nyModify))
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
      if(OrderType()== 0)
      {
         double currentPriceBuy = MarketInfo(Symbol(),MODE_BID);
         result=OrderClose(OrderTicket(),OrderLots(),currentPriceBuy,nySlippage,Blue);
         Print("Order closing at price: ", currentPriceBuy);
      }
      if(OrderType()== 1)
      {
         double currentPriceSell = MarketInfo(Symbol(),MODE_ASK);
         result=OrderClose(OrderTicket(),OrderLots(),currentPriceSell,nySlippage,Blue);
         Print("Order closing at price: ", currentPriceSell);
      }
      if(!result)Print("CloseOpenOrders failed with error#",GetLastError());
   }
}

void ClosePartialOrders()
{
   bool result=false;
   for(int i=0;i<OrdersTotal();i++)
   {
      OrderSelect(i,SELECT_BY_POS);
      if(OrderType()== 0)
      {
         double currentPriceBuy = MarketInfo(Symbol(),MODE_BID);
         result=OrderClose(OrderTicket(),0.01,currentPriceBuy,nySlippage,Blue);
         Print("Order closing at price: ", currentPriceBuy);
      }
      if(OrderType()== 1)
      {
         double currentPriceSell = MarketInfo(Symbol(),MODE_ASK);
         result=OrderClose(OrderTicket(),0.01,currentPriceSell,nySlippage,Blue);
         Print("Order closing at price: ", currentPriceSell);
      }
      if(!result)Print("CloseOpenOrders failed with error#",GetLastError());
   }
}


int CheckTodaysOrders()
{
   int TodaysOrders = 0;   
   for(int i = OrdersTotal()-1; i >=0; i--)
   {   
      OrderSelect(i, SELECT_BY_POS,MODE_TRADES);   
      if(TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent())&& (OrderProfit() < (-10)))
      {   
         TodaysOrders += 1;  
      }

   }

   for(i = OrdersHistoryTotal()-1; i >=0; i--)
   {   
      OrderSelect(i, SELECT_BY_POS,MODE_HISTORY);   
      if(TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent())&& (OrderProfit() < (-10)))
      {   
         TodaysOrders += 1;     
      }
   
   }
   
   return(TodaysOrders);

}