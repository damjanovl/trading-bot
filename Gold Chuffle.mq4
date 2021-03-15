double goldValues[2];
double goldLow = 0;
double goldHigh = 0;
double buySlip = 0;
double sellSlip = 0;
double buySlip2 =0;
double sellSlip2 = 0;
double dailyLoss = 0;
double goldRange = 8.0;
double goldSlippage = 0.2;
double goldSlippage2 = 0.6;
extern double DrawdownPercent = 4;



void OnTick()
  {
      if(OnionTags(goldValues)&& (goldLow == 0)&& (goldHigh == 0))
         {
            goldHigh = goldValues[0];
            goldLow = goldValues[1];
            buySlip = (goldHigh + goldSlippage);
            buySlip2 =  (goldHigh + goldSlippage2);
            sellSlip = (goldLow - goldSlippage);
            sellSlip2 = (goldLow - goldSlippage2);
             
            
            Print("Gold Low is: ", goldLow);
            Print("Gold High is: ", goldHigh);
         }
         
       if((OrdersTotal() < 1)&&(goldHigh > 0)&&(goldLow > 0)&&((goldHigh - goldLow) < goldRange)&& CheckTodaysOrders()< 2 )
         {
            double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
            double PriceBid = MarketInfo(Symbol(), MODE_BID);
            if((buySlip >= PriceAsk)&&(PriceAsk <= buySlip2))
               {
                  double goldHighTP = (goldHigh + 25.0);
                  int orderIDBuy = OrderSend(NULL,OP_BUY,0.5,goldHigh,1,goldLow,goldHighTP);
               }
            if((sellSlip <= PriceBid)&&(PriceBid <= sellSlip2))
               {
                  double goldLowTP = (goldLow - 25.0);
                  int orderIDSell = OrderSend(NULL,OP_SELL,0.5,goldLow,1,goldHigh,goldLowTP);
               }
         
         }
         
 
         datetime time=TimeLocal();
         string HoursAndMinutes=TimeToString(time,TIME_MINUTES);        
         if(StringSubstr(HoursAndMinutes,0,5)=="11:59")
         {
            goldValues[0]=0;
            goldValues[1]=0;
            goldLow = 0;
            goldHigh = 0;
         }
            
   
  }
//+------------------------------------------------------------------+ 
bool OnionTags(double& GOLDValues[])
   {
       //Initialize variables
       int WindowSizeInBars=96;        //number of candles to scan
       datetime time=TimeLocal();
       double goldHighest=High[0];
       double goldLowest=Low[0];
       string HoursAndMinutes=TimeToString(time,TIME_MINUTES);
       bool running = True;
     
          //Scan the 12 candles and update values of highest and lowest

         if(StringSubstr(HoursAndMinutes,0,5)=="20:00")
         {
           for(int i=0; i<=WindowSizeInBars; i++)
          {
               if(High[i]>goldHighest) goldHighest=High[i];
               if(Low[i]<goldLowest) goldLowest=Low[i];
          }         
   
            GOLDValues[0] = goldHighest;
            GOLDValues[1] = goldLowest;
            return True;
            //return values;
         }
                    
         return False;
   }
   
void ModifyOrder()
{
   double goldModify = 0.2;
   
   double pipGainer = 2.5;    //when its in a range of 2.4 - 2.6 profit
   double pipGainer2 = 5.0;   //when its in a range of 4.9 - 5.1 profit
   double pipGainer3 = 10.0;  //when its in a range 
   double pipGainer4 = 15.0;
   double pipGainer5 = 20.0;
   

   
   double stopLossBuy1 = NormalizeDouble((goldHigh + 0.1),6);
   double stopLossBuy2 = NormalizeDouble((goldHigh + pipGainer),6);
   double stopLossBuy3 = NormalizeDouble((goldHigh + pipGainer2),6);
   double stopLossBuy4 = NormalizeDouble((goldHigh + pipGainer3),6);
   double stopLossBuy5 = NormalizeDouble((goldHigh + pipGainer4),6);
   double stopLossBuy6 = NormalizeDouble((goldHigh + pipGainer5),6);

   
   double stopLossSell1 = NormalizeDouble((goldLow - 0.1),6);
   double stopLossSell2 = NormalizeDouble((goldLow - pipGainer),6);
   double stopLossSell3 = NormalizeDouble((goldLow - pipGainer2),6);
   double stopLossSell4 = NormalizeDouble((goldLow - pipGainer3),6);
   double stopLossSell5 = NormalizeDouble((goldLow - pipGainer4),6);
   double stopLossSell6 = NormalizeDouble((goldLow - pipGainer5),6);

   OrderSelect(0, SELECT_BY_POS, MODE_TRADES); 
   bool res = False;
   if(OrderType()==0||2||3)
   {
      if(OrderProfit() > pipGainer)
      { 
         double currentPriceBuy = MarketInfo(Symbol(),MODE_ASK);
         //double TrailingStopPriceBuy1 = (nyHigh + pipGainer);
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer + goldModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer - goldModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy1,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy One. Error Code=", GetLastError());
            }
            else
            {
               //ClosePartialOrders(); 
            }
         }
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer2 + goldModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer2 - goldModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy2,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy Two. Error Code=", GetLastError());
            }
         }
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer3 + goldModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer3 - goldModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy3,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy Three. Error Code=", GetLastError());
            }
         }
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer4 + goldModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer4 - goldModify))
         {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossBuy4,OrderTakeProfit(),0,Blue);
            if(!res)
            {
               Print("Error in OrderModify Buy Four. Error Code=", GetLastError());
            }
         }
         if(currentPriceBuy <=(OrderOpenPrice() + pipGainer5 + goldModify)&& currentPriceBuy >=(OrderOpenPrice() + pipGainer5 - goldModify))
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
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer + goldModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer - goldModify))   
         {  
            res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell1,OrderTakeProfit(),0,Yellow);
            if(!res)
            {           
               Print("Error in OrderModify Sell One. Error Code=", GetLastError());              
            }
            else
            {
               //ClosePartialOrders();
            }
         } 
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer2 + goldModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer2 - goldModify))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell2,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Two. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer3 + goldModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer3 - goldModify))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell3,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Three. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer4 + goldModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer4 - goldModify))
         {
               res=OrderModify(OrderTicket(),OrderOpenPrice(),stopLossSell4,OrderTakeProfit(),0,Yellow);
               if(!res)
               {           
                  Print("Error in OrderModify Sell Four. Error Code=", GetLastError());              
               }
         }
         if(currentPriceSell <=(OrderOpenPrice() - pipGainer5 + goldModify)&& currentPriceSell >=(OrderOpenPrice() - pipGainer5 - goldModify))
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

int CheckTodaysOrders()
{
   int TodaysOrders = 0;   
   for(int i = OrdersTotal()-1; i >=0; i--)
   {   
      OrderSelect(i, SELECT_BY_POS,MODE_TRADES);   
      if(TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent()))
      {   
         TodaysOrders += 1;  
      }

   }

   for(i = OrdersHistoryTotal()-1; i >=0; i--)
   {   
      OrderSelect(i, SELECT_BY_POS,MODE_HISTORY);   
      if(TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent()))
      {   
         TodaysOrders += 1;     
      }
   
   }
   
   return(TodaysOrders);

}