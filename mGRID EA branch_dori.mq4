#include <stdlib.mqh>

//---- input parameters ---------------------------------------------+
extern int INCREMENT = 35;
extern double LOTS = 0.1;
extern double FATOR_HEDGE = 4.5;
extern int MAGIC = 1803;
extern bool CONTINUE = true;


//didi
extern int       MovingAvarageSlow = 25;
extern int       MovingAvarageNorm = 8;
extern int       MovingAvarageFast = 3;

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
        
        
         double iStoc = iStochastic(NULL,PERIOD_H1,5,3,3,MODE_SMA,0,MODE_MAIN,0); 
         double fast = iMA(NULL, PERIOD_H1, MovingAvarageFast, 0, MODE_SMA, PRICE_CLOSE, 0);
         double norm = iMA(NULL, PERIOD_H1, MovingAvarageNorm, 0, MODE_SMA, PRICE_CLOSE, 0);
         double slow = iMA(NULL, PERIOD_H1, MovingAvarageSlow, 0, MODE_SMA, PRICE_CLOSE, 0);
         
         if(iStoc > 95 || iStoc < 5){
            if(fast>norm && norm > slow){ //compra
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
            }else if(fast<norm && norm < slow){//venda
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