double asianValues[2];
double asianLow = 0;
double asianHigh = 0;
double buySlip1 = 0;
double buySlip2 = 0;
double sellSlip1 = 0;
double sellSlip2 = 0;
double dailyLoss = 0;
double asianSlippage = 0.0001;
extern double DrawdownPercent = 4;
double stopLossBuy = (asianLow - 0.004);
double stopLossSell = (asianHigh + 0.004);



void OnTick()
    {
//---
   if(OnionTags(asianValues)&& (asianHigh==0)&& (asianLow==0))
   {       
      asianHigh = asianValues[0];
      asianLow = asianValues[1];
      buySlip1 = (asianHigh + asianSlippage);
      buySlip2 = (asianHigh - asianSlippage);
      sellSlip1 = (asianLow + asianSlippage);
      sellSlip2 = (asianLow - asianSlippage);     
      
      Print("Asian LOW: ", asianLow);
      Print("Asian HIGH: ", asianHigh);
   }
   
	
   if((OrdersTotal() < 1)&&(asianHigh> 0)&&(asianLow>0)&&(CheckTodaysOrders() < 3))
   {
      double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
      double PriceBid = MarketInfo(Symbol(), MODE_BID);
      if((buySlip1 >= PriceAsk)&& (buySlip2 <= PriceAsk))
      {
         double asianHighTp = (asianHigh - 0.015);  
         int orderIDBuy = OrderSend(NULL,OP_SELL,0.02,asianHigh,asianSlippage,stopLossSell,asianHighTp);
      }       
      if((sellSlip1 >= PriceBid)&& (sellSlip2 <= PriceBid))
      {
         double asianLowTp = (asianLow + 0.015);
         int orderIDSell = OrderSend(NULL,OP_BUY,0.02,asianLow,asianSlippage,stopLossBuy,asianLowTp);  
      }                 
   }
   
   if(OrdersTotal() == 1)
   {
      ModifyOrder();
   }
  
   
   if((1-AccountEquity()/AccountBalance())*100>NormalizeDouble(DrawdownPercent, 2))
   {
      CloseOpenOrders();
      asianLow = 0;
      asianHigh = 0;
   }
   
   datetime time=TimeLocal();
   string HoursAndMinutes=TimeToString(time,TIME_MINUTES);

   if(StringSubstr(HoursAndMinutes,0,5)=="07:45")
   {
      if(OrdersTotal() > 0)
      {          
        CloseOpenOrders();         
      }         
       asianValues[0]=0;
       asianValues[1]=0;
       asianLow = 0;
       asianHigh = 0;
   }
  }
//+------------------------------------------------------------------+
bool OnionTags(double& AsianValues[])
   {
       //Initialize variables
       int WindowSizeInBars=48;        //number of candles to scan
       datetime time=TimeLocal();
       double asianHighest=High[0];
       double asianLowest=Low[0];
       string HoursAndMinutes=TimeToString(time,TIME_MINUTES);
       bool running = True;
     
          //Scan the 48 candles and update values of highest and lowest

         if(StringSubstr(HoursAndMinutes,0,5)=="00:00")
         {
           for(int i=0; i<=WindowSizeInBars; i++)
          {
               if(High[i]>asianHighest) asianHighest=High[i];
               if(Low[i]<asianLowest) asianLowest=Low[i];
          }         
   
            asianValues[0] = asianHighest;
            asianValues[1] = asianLowest;
            return True;
            //return values;
         }
                    
         return False;
   }
   
   
void ModifyOrder()
{
   double pipGainer = 0.0025;
   double pipGainer2 = 0.005;
   double pipGainer3 = 0.0075;
   double pipGainer4 = 0.0100;
   double pipGainer5 = 0.0125;

   
   double stopLossBuy1 = NormalizeDouble((asianHigh + 0.0001),6);
   double stopLossBuy2 = NormalizeDouble((asianHigh + pipGainer),6);
   double stopLossBuy3 = NormalizeDouble((asianHigh + pipGainer2),6);
   double stopLossBuy4 = NormalizeDouble((asianHigh + pipGainer3),6);
   double stopLossBuy5 = NormalizeDouble((asianHigh + pipGainer4),6);
   double stopLossBuy6 = NormalizeDouble((asianHigh + pipGainer5),6);

   
   double stopLossSell1 = NormalizeDouble((asianLow - 0.0001),6);
   double stopLossSell2 = NormalizeDouble((asianLow - pipGainer),6);
   double stopLossSell3 = NormalizeDouble((asianLow - pipGainer2),6);
   double stopLossSell4 = NormalizeDouble((asianLow - pipGainer3),6);
   double stopLossSell5 = NormalizeDouble((asianLow - pipGainer4),6);
   double stopLossSell6 = NormalizeDouble((asianLow - pipGainer5),6);

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
               ClosePartialOrders(); 
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
               ClosePartialOrders();
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
      if(OrderType()== 0)
      {
         double currentPriceBuy = MarketInfo(Symbol(),MODE_BID);
         result=OrderClose(OrderTicket(),OrderLots(),currentPriceBuy,asianSlippage,Blue);
         Print("Order closing at price: ", currentPriceBuy);
      }
      if(OrderType()== 1)
      {
         double currentPriceSell = MarketInfo(Symbol(),MODE_ASK);
         result=OrderClose(OrderTicket(),OrderLots(),currentPriceSell,asianSlippage,Blue);
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
         result=OrderClose(OrderTicket(),0.01,currentPriceBuy,asianSlippage,Blue);
         Print("Order closing at price: ", currentPriceBuy);
      }
      if(OrderType()== 1)
      {
         double currentPriceSell = MarketInfo(Symbol(),MODE_ASK);
         result=OrderClose(OrderTicket(),0.01,currentPriceSell,asianSlippage,Blue);
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