#include <stdlib.mqh>

//---- input parameters ---------------------------------------------+
extern int INCREMENT = 150;
extern double LOTS = 0.1;
extern double FATOR_HEDGE = 5;
extern int MAGIC = 1803;
extern bool CONTINUE = true;


//----------Magisterka---------
#define TREND_UP                                                     0
#define TREND_DOWN                                                   1
#define TREND_HORIZONTAL                                             2

#define MA_DISTANCE                                                  3
#define MA_FAST                                                     10
#define MA_SLOW                                                     15

//http://docs.mql4.com/constants/chartconstants/enum_timeframes
extern int M_PERIOD  = 60;

double prevPrice=NULL;
bool openSell=false; 
bool openBuy=false;
//----------Magisterka---------


//+------------------------------------------------------------------+

bool Enter = true;

int init() {
    return (0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
    return (0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
    int ticket, cpt, total = 0, BuyGoalProfit, SellGoalProfit;
    double BuyGoal = 0, SellGoal = 0, InitialPrice = 0;
    //----   
    
    
    //----------Magisterka---------
    openSell=false; 
    openBuy=false;
    
   if(prevPrice==NULL){
      RefreshRates(); 
      prevPrice=Ask;
      return(0);
   }
   //----------Magisterka--------- 

    if (INCREMENT < MarketInfo(Symbol(), MODE_STOPLEVEL)) INCREMENT = 1 + MarketInfo(Symbol(), MODE_STOPLEVEL);
    if (LOTS < MarketInfo(Symbol(), MODE_MINLOT)) {
        Comment("Not Enough Free Margin to begin");
        return (0);
    }
    for (cpt = 0; cpt < OrdersTotal(); cpt++) {
        OrderSelect(cpt, SELECT_BY_POS, MODE_TRADES);
        if (OrderMagicNumber() == MAGIC && OrderSymbol() == Symbol()) {
            total++;
            if (!InitialPrice) InitialPrice = StrToDouble(OrderComment());
        }
    }
    if (total < 1 && Enter) {
        if (AccountFreeMargin() < (100 * LOTS)) {
            Print("Not enough free margin to begin");
            return (0);
        }
        
        //verifica os criterios
        bandsOpenCriteria();
        
         if(openBuy){ //compra
           RefreshRates();
           InitialPrice = Ask - INCREMENT * Point;
           SellGoal = InitialPrice - 2 * INCREMENT * Point;
           BuyGoal = InitialPrice + 2 * INCREMENT * Point;
            
         
            ticket = OrderSend(Symbol(), OP_BUY, LOTS, Ask , 2, SellGoal, BuyGoal, DoubleToStr(InitialPrice, MarketInfo(Symbol(), MODE_DIGITS)), MAGIC, 0);
            if (ticket > 0) {
                BuyGoalProfit = CheckProfits(OP_BUY, InitialPrice);
            }else{
               Print("Cannot trade, error: ",ErrorDescription(GetLastError()));  
               PrintFormat("OP:"+(InitialPrice +  INCREMENT * Point)+" SL:"+SellGoal+" TP:"+BuyGoal);
            }
         }else if(openSell){//venda
           RefreshRates();
           InitialPrice = Bid + INCREMENT * Point;
           SellGoal = InitialPrice - 2 * INCREMENT * Point;
           BuyGoal = InitialPrice + 2 * INCREMENT * Point;
         
            ticket = OrderSend(Symbol(), OP_SELL, LOTS, Bid , 2, BuyGoal, SellGoal, DoubleToStr(InitialPrice, MarketInfo(Symbol(), MODE_DIGITS)), MAGIC, 0);
            if (ticket > 0) {
                BuyGoalProfit = CheckProfits(OP_BUY, InitialPrice);
            }else{
               Print("Cannot trade, error: ",ErrorDescription(GetLastError()));  
               PrintFormat("OP:"+(InitialPrice +  INCREMENT * Point)+" SL:"+SellGoal+" TP:"+BuyGoal);
            }            
         }         
    }
    else 
    {
        BuyGoal = InitialPrice + INCREMENT * 2 * Point;
        SellGoal = InitialPrice - INCREMENT * 2 * Point;
        total = OrdersHistoryTotal();
        for (cpt = 0; cpt < total; cpt++) {
            OrderSelect(cpt, SELECT_BY_POS, MODE_HISTORY);
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGIC && StrToDouble(OrderComment()) == InitialPrice) {
                EndSession();
                return (0);
            }
        }
        BuyGoalProfit = CheckProfits(OP_BUY, InitialPrice);
        SellGoalProfit = CheckProfits(OP_SELL, InitialPrice);

        if (BuyGoalProfit < (INCREMENT / 1.1) && Bid < InitialPrice)
        {
             for (cpt = 5; cpt >= 1 && BuyGoalProfit < SellGoalProfit * FATOR_HEDGE; cpt--) {
                 if (Ask <= (InitialPrice + (cpt * INCREMENT - MarketInfo(Symbol(), MODE_STOPLEVEL)) * Point)) {
                     double op = InitialPrice + INCREMENT * Point;                        
                     double tp = INCREMENT/LOTS;                        
                     int diferenca = SellGoalProfit * FATOR_HEDGE - BuyGoalProfit;                        
                     double newlot = NormalizeDouble(diferenca / tp, 2) + MarketInfo(Symbol(), MODE_MINLOT);                        
                     if (newlot > MarketInfo(Symbol(), MODE_MAXLOT))
                         newlot = MarketInfo(Symbol(), MODE_MAXLOT);
                     ticket = OrderSend(Symbol(), OP_BUYSTOP, newlot, InitialPrice + INCREMENT * Point, 2, SellGoal, BuyGoal, DoubleToStr(InitialPrice, MarketInfo(Symbol(), MODE_DIGITS)), MAGIC, 0);
                 }
                 if (ticket > 0) {
                     BuyGoalProfit = CheckProfits(OP_BUY, InitialPrice);
                 }else{
                     Print("Cannot trade, error: ",ErrorDescription(GetLastError())); 
                     PrintFormat("OP:",op," SL:",SellGoal," TP:",BuyGoal); 
                 }
             }
        }
        if (SellGoalProfit < (INCREMENT / 1.1) && Bid > InitialPrice)
        {
             for (cpt = 5; cpt >= 1 && SellGoalProfit < BuyGoalProfit * FATOR_HEDGE; cpt--) {
                 if (Bid >= (InitialPrice - (cpt * INCREMENT - MarketInfo(Symbol(), MODE_STOPLEVEL)) * Point)) {
                     op = 0;
                     tp = 0;
                     tp = 0;
                     diferenca = 0;
                     newlot = 0;
                     op = InitialPrice - INCREMENT * Point;                        
                     tp = INCREMENT/LOTS;                        
                     diferenca = BuyGoalProfit * FATOR_HEDGE - SellGoalProfit;                        
                     newlot = NormalizeDouble(diferenca / tp, 2) + MarketInfo(Symbol(), MODE_MINLOT);
                     if (newlot > MarketInfo(Symbol(), MODE_MAXLOT))
                         newlot = MarketInfo(Symbol(), MODE_MAXLOT);
                     ticket = OrderSend(Symbol(), OP_SELLSTOP, newlot, InitialPrice - INCREMENT * Point, 2, BuyGoal, SellGoal, DoubleToStr(InitialPrice, MarketInfo(Symbol(), MODE_DIGITS)), MAGIC, 0);
                 }
                 if (ticket > 0) {
                     SellGoalProfit = CheckProfits(OP_SELL, InitialPrice);
                 }else{
                     Print("Cannot trade, error: ",ErrorDescription(GetLastError()));  
                     PrintFormat("OP:",op," SL:",BuyGoal," TP:",SellGoal);     
                 }
             }
        }
    }
    //+------------------------------------------------------------------+   

    Comment("mGRID EXPERT ADVISOR ver 2.0\n",
        "FX Acc Server:", AccountServer(), "\n",
        "Date: ", Month(), "-", Day(), "-", Year(), " Server Time: ", Hour(), ":", Minute(), ":", Seconds(), "\n",
        "Minimum Lot Sizing: ", MarketInfo(Symbol(), MODE_MINLOT), "\n",
        "Account Balance:  $", AccountBalance(), "\n",
        "Symbol: ", Symbol(), "\n",
        "Price:  ", NormalizeDouble(Bid, 4), "\n",
        "Pip Spread:  ", MarketInfo(Symbol(), MODE_SPREAD), "\n",
        "Increment=" + INCREMENT, "\n",
        "Lots:  ", LOTS, "\n");
    return (0);
}

//+------------------------------------------------------------------+

int CheckProfits(int Goal, double InitialPrice) {
    int profit = 0, cpt;
    if (Goal == OP_BUY) {
        for (cpt = 0; cpt < OrdersTotal(); cpt++) {
            OrderSelect(cpt, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() == Symbol() && StrToDouble(OrderComment()) == InitialPrice) {
                if (OrderType() == OP_BUY) profit += (OrderTakeProfit() - OrderOpenPrice()) / Point * OrderLots() / LOTS;
                if (OrderType() == OP_SELL) profit -= (OrderStopLoss() - OrderOpenPrice()) / Point * OrderLots() / LOTS;
                if (OrderType() == OP_BUYSTOP) profit += (OrderTakeProfit() - OrderOpenPrice()) / Point * OrderLots() / LOTS;
            }
        }
        return (profit);
    } else {
        for (cpt = 0; cpt < OrdersTotal(); cpt++) {
            OrderSelect(cpt, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() == Symbol() && StrToDouble(OrderComment()) == InitialPrice) {
                if (OrderType() == OP_BUY) profit -= (OrderOpenPrice() - OrderStopLoss()) / Point * OrderLots() / LOTS;
                if (OrderType() == OP_SELL) profit += (OrderOpenPrice() - OrderTakeProfit()) / Point * OrderLots() / LOTS;
                if (OrderType() == OP_SELLSTOP) profit += (OrderOpenPrice() - OrderTakeProfit()) / Point * OrderLots() / LOTS;
            }
        }
        return (profit);
    }
}

bool EndSession() {
    int cpt, total = OrdersTotal();
    for (cpt = 0; cpt < total; cpt++) {
        Sleep(3000);
        OrderSelect(cpt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() == Symbol() && OrderType() > 1) OrderDelete(OrderTicket());
        else if (OrderSymbol() == Symbol() && OrderType() == OP_BUY) OrderClose(OrderTicket(), OrderLots(), Bid, 3);
        else if (OrderSymbol() == Symbol() && OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, 3);

    }
    if (!CONTINUE) Enter = false;
    return (true);
}

void bandsOpenCriteria()
{
   double midBand=iMA(NULL,M_PERIOD,20,0,MODE_SMA,PRICE_CLOSE,0);
      
   if(TREND_UP==trend())
   {
      RefreshRates();
      if(Ask>=midBand && prevPrice<midBand)
         openBuy=true;

   }
   else if(TREND_DOWN==trend())
   {
      RefreshRates();
      if(Bid<=midBand && prevPrice>midBand)
         openSell=true;
   }
}

//+------------------------------------------------------------------+
//| return trend 0-TREND_UP 1-TREND_DOWN 2-TREND_HORIZONTAL          |
//+------------------------------------------------------------------+
int trend()
{
   double diff=iMA(NULL,M_PERIOD,MA_FAST,0,MODE_EMA,PRICE_CLOSE,0)-iMA(NULL,M_PERIOD,MA_SLOW,0,MODE_EMA,PRICE_CLOSE,0);
   if(diff-Point*MA_DISTANCE > 0)
      return(TREND_UP);
   else if(diff+Point*MA_DISTANCE < 0)
      return(TREND_DOWN);
   else
      return(TREND_HORIZONTAL);
}