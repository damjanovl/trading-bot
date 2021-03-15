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
double goldSlippage2 = 0.5;
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
         
       if((OrdersTotal() < 1)&&(goldHigh > 0)&&(goldLow > 0)&&((goldHigh - goldLow) < goldRange)&& CheckTodaysOrders()< 1 )
         {
            double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
            double PriceBid = MarketInfo(Symbol(), MODE_BID);
            if((buySlip >= PriceAsk)&&(PriceAsk <= buySlip2))
               {
                  double goldHighTP = (goldHigh + (goldHigh-goldLow));
                  int orderIDBuy = OrderSend(NULL,OP_BUY,0.5,goldHigh,1,goldLow,goldHighTP);
               }
            if((sellSlip <= PriceBid)&&(PriceBid <= sellSlip2))
               {
                  double goldLowTP = (goldLow - (goldHigh-goldLow));
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
