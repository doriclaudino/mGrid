//+------------------------------------------------------------------+
//|                                                 mGrid_cleber.mq4 |
//|                                          dori.claudino@gmail.com |
//|                                             fb.com/dori.claudino |
//+------------------------------------------------------------------+
#property copyright "dori.claudino@gmail.com"
#property link      "fb.com/dori.claudino"



//---- input parameters ---------------------------------------------+

extern int       INCREMENT=20;
extern double    LOTS=0.1;
extern int       MAGIC=1803;
extern bool      CONTINUE=true;
//+------------------------------------------------------------------+
extern bool      UseEntryTime=false;
extern int       EntryTime=0;
double           T_BUY,T_SELL,T_COMPRA,T_VENDA;

//+------------------------------------------------------------------+

bool Enter=true;
extern int multiplicador = 4;


//didi
extern int       MovingAvarageSlow = 25;
extern int       MovingAvarageNorm = 8;
extern int       MovingAvarageFast = 3;

bool okToTrade;
int oldbar;
int directionMACD = 0;
int countAboveMA = 0;
int directionCross = 0;//Será considerado 1 compra e -1 venda
int ticket = 0;


int init()
  {
//+------------------------------------------------------------------+ 
  	if(MarketInfo(Symbol(),MODE_DIGITS)==3 || MarketInfo(Symbol(),MODE_DIGITS)==5) {INCREMENT*=10;}
    
//+------------------------------------------------------------------+
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   int ticket, cpt, profit, total=0, BuyGoalProfit, SellGoalProfit;
   double BuyGoal=0, SellGoal=0, spread=(Ask-Bid)/Point, InitialPrice=0;
   T_BUY=0;
   T_SELL=0;
   T_COMPRA=0;
   T_VENDA=0;
//----
  
   if(INCREMENT<MarketInfo(Symbol(),MODE_STOPLEVEL)+spread) INCREMENT=1+MarketInfo(Symbol(),MODE_STOPLEVEL)+spread;
   if(LOTS<MarketInfo(Symbol(),MODE_MINLOT))
   {
      Comment("Not Enough Free Margin to begin");
      return(0);
   }
   for(cpt=0;cpt<OrdersTotal();cpt++)
   {
      OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()==MAGIC && OrderSymbol()==Symbol())
      {
         total++;
         if(!InitialPrice) InitialPrice=StrToDouble(OrderComment());
      }
   }
   if(total<1 && Enter && (!UseEntryTime || (UseEntryTime && Hour()==EntryTime)))
   {
      if(AccountFreeMargin()<(100*LOTS))
      {
         Print("Not enough free margin to begin");
         return(0);
      }
      
      // - Open Check - Start Cycle
      didi();
      
      if(okToTrade==true){
         //compra   
         if(directionMACD==1 && directionCross==1){
            InitialPrice=Ask;
            SellGoal=InitialPrice-2*INCREMENT*Point;
            BuyGoal=InitialPrice+2*INCREMENT*Point;
            OrderSend(Symbol(),OP_BUY,LOTS,Ask,5,SellGoal,BuyGoal,DoubleToStr(InitialPrice,MarketInfo(Symbol(),MODE_DIGITS)),MAGIC,NULL,Blue); 
            OrderSend(Symbol(),OP_SELLSTOP,LOTS*multiplicador,InitialPrice-(INCREMENT)*Point,2,BuyGoal+spread*Point,SellGoal+spread*Point,DoubleToStr(InitialPrice,MarketInfo(Symbol(),MODE_DIGITS)),MAGIC,0);
         }
         //venda
         else if(directionMACD==-1 && directionCross==-1){
            InitialPrice=Bid;
            SellGoal=InitialPrice-2*INCREMENT*Point;
            BuyGoal=InitialPrice+2*INCREMENT*Point;
            OrderSend(Symbol(),OP_SELL,LOTS,Bid,5,BuyGoal,SellGoal,DoubleToStr(InitialPrice,MarketInfo(Symbol(),MODE_DIGITS)),MAGIC,NULL,Red); 
            OrderSend(Symbol(),OP_BUYSTOP,LOTS*multiplicador,InitialPrice+(INCREMENT)*Point,2,SellGoal,BuyGoal,DoubleToStr(InitialPrice,MarketInfo(Symbol(),MODE_DIGITS)),MAGIC,0);
         }
      }   
    } // initial setup done - all channels are set up
    else // We have open Orders
    {
      BuyGoal=InitialPrice+INCREMENT*2*Point;
      SellGoal=InitialPrice-INCREMENT*2*Point;
      total=OrdersHistoryTotal();
      if(Bid>=BuyGoal || Ask<=SellGoal){
         for(cpt=0;cpt<total;cpt++)
         {
            OrderSelect(cpt,SELECT_BY_POS,MODE_HISTORY);
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC &&  StrToDouble(OrderComment())==InitialPrice){EndSession();return(0);}
         }
      }   
   
      Total();
      
      if(T_COMPRA<T_SELL*multiplicador)
      // - Incriment Lots Buy
      {
         if(Ask<=(InitialPrice+(INCREMENT-MarketInfo(Symbol(),MODE_STOPLEVEL))*Point))
         {
            ticket=OrderSend(Symbol(),OP_BUYSTOP,T_SELL*multiplicador-T_COMPRA,InitialPrice+INCREMENT*Point,2,SellGoal,BuyGoal,DoubleToStr(InitialPrice,MarketInfo(Symbol(),MODE_DIGITS)),MAGIC,0);
         } 
      } 
      if(T_VENDA<T_BUY*multiplicador)
      // - Increment Lots Sell
      {
         if(Bid>=(InitialPrice-(INCREMENT-MarketInfo(Symbol(),MODE_STOPLEVEL))*Point))
         {
            ticket=OrderSend(Symbol(),OP_SELLSTOP,T_BUY*multiplicador-T_VENDA,InitialPrice-INCREMENT*Point,2,BuyGoal+spread*Point,SellGoal+spread*Point,DoubleToStr(InitialPrice,MarketInfo(Symbol(),MODE_DIGITS)),MAGIC,0);
         }
      }
   }
//+------------------------------------------------------------------+   
    Comment("mGrid_mod_002\n",
            "FX Acc Server:",AccountServer(),"\n",
            "Date: ",Month(),"-",Day(),"-",Year()," Server Time: ",Hour(),":",Minute(),":",Seconds(),"\n",
            "Minimum Lot Sizing: ",MarketInfo(Symbol(),MODE_MINLOT),"\n",
            "Account Balance:  $",AccountBalance(),"\n",
            "Symbol: ", Symbol(),"\n",
            "Price:  ",NormalizeDouble(Bid,4),"\n",
            "Pip Spread:  ",MarketInfo("EURUSD",MODE_SPREAD),"\n",
            "Increment=" + INCREMENT,"\n",
            "Lots:  ",LOTS,"\n");
   return(0);
}

//+------------------------------------------------------------------+
void Total(){
    int cpt;   
   for(cpt=0;cpt<OrdersTotal();cpt++)
   {
      OrderSelect(cpt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
      {
         if(OrderType()==OP_BUY) T_BUY+= OrderLots();
         if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUY) T_COMPRA+= OrderLots();
         if(OrderType()==OP_SELL) T_SELL+= OrderLots();
         if(OrderType()==OP_SELLSTOP || OrderType()==OP_SELL) T_VENDA+= OrderLots();
      }
   }
}

bool EndSession()
{
   int cpt, total=OrdersTotal();
   for(cpt=0;cpt<total;cpt++)
   {
      Sleep(3000);
      OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderType()>1) OrderDelete(OrderTicket());
      else if(OrderSymbol()==Symbol() && OrderType()==OP_BUY) OrderClose(OrderTicket(),OrderLots(),Bid,3);
      else if(OrderSymbol()==Symbol() && OrderType()==OP_SELL) OrderClose(OrderTicket(),OrderLots(),Ask,3);
      
      }
      if(!CONTINUE)  Enter=false;
      return(true);
}

void didi(){
   if (oldbar != Time[0]) { oldbar = Time[0];  
   okToTrade = true;
   int i;
   
   //Valida condição dos indicadores:
   //MACD
   double arrayMACD[6];
   double arraySignal[6];
   for (i=1;i<5;i++) {
      arrayMACD[i] = iMACD(NULL, PERIOD_M15, 9, 20, 9, PRICE_CLOSE, MODE_MAIN, i-1) * 10000;
      arraySignal[i] = iMACD(NULL, PERIOD_M15, 9, 20, 9, PRICE_CLOSE, MODE_SIGNAL, i-1) * 10000;
   }
 
   if (arrayMACD[1] > arraySignal[1] && arrayMACD[4] < arraySignal[4]) { directionMACD = 1; 
   //Print("MACD COMPRA"); okToTrade=true;
   }
   else if (arrayMACD[1] < arraySignal[1] && arrayMACD[4] > arraySignal[4]) { directionMACD = -1; 
   //Print("MACD VENDA"); okToTrade=true;
   }
   else { okToTrade = false;}
   
   
   //Volume
   double arrayVolume[20];
   double volumeMA = 0;
   double volumeVal = 0;
   for (i=1;i<=20;i++) { arrayVolume[i] = Volume[i]; }
   for(i=0;i<=7;i++) {
      volumeMA = iMAOnArray(arrayVolume, 0, 10, 0, MODE_SMA, i);
      volumeVal = Volume[i+1];
      if (volumeMA < volumeVal) { countAboveMA++; }
   }   
   if (countAboveMA <= 4) {okToTrade = false; }
   //else { Print("VOLUME alto: ",countAboveMA);}
   
   
   
   //Medias
   double diffFastSlow[3];
   double diffNormSlow[3];
   double fast = 0;
   double norm = 0;
   double slow = 0;
   double max = 0;
   double min = 0;
   for (i=0;i<3;i++) {
      fast = iMA(NULL, 0, MovingAvarageFast, 0, MODE_SMA, PRICE_CLOSE, i) * 10000; //Print("fast ",fast);
      norm = iMA(NULL, 0, MovingAvarageNorm, 0, MODE_SMA, PRICE_CLOSE, i) * 10000; //Print("norm ",norm);
      slow = iMA(NULL, 0, MovingAvarageSlow, 0, MODE_SMA, PRICE_CLOSE, i) * 10000; //Print("slow ",slow);
      diffFastSlow[i] = (slow - fast);
      diffNormSlow[i] = (slow - norm); 
   }

      //cruzamento das medias moveis por cattoni.   
      fast = iMA(NULL, 0, MovingAvarageFast, 0, MODE_SMA, PRICE_CLOSE, 1) * 100; 
      slow = iMA(NULL, 0, MovingAvarageSlow, 0, MODE_SMA, PRICE_CLOSE, 1) * 100; 
      max = High[1] * 100;
      min = Low[1] * 100;
      if ( max > fast &&  min < slow ) {
         if ((diffFastSlow[0] < 0 && diffFastSlow[2] > 0) && (diffNormSlow[0] < 0 && diffNormSlow[2] > 0)) {
            directionCross = 1; 
            //Print("Cruzamento COMPRA");
            //okToTrade=true;
         } else if ((diffFastSlow[0] > 0 && diffFastSlow[2] < 0) && (diffNormSlow[0] > 0 && diffNormSlow[2] < 0)) {
            directionCross = -1; 
            //Print("Cruzamento VENDA");
            //okToTrade=true;
         } else { okToTrade = false;}
      }  
   }
}
