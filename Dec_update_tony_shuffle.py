import logging
import json
import re
from pprint import pprint

from currency_converter import CurrencyConverter
from oandapyV20 import API
import oandapyV20.endpoints.trades as trades
import oandapyV20.endpoints.pricing as pricing
import oandapyV20.endpoints.accounts as accounts
import oandapyV20.endpoints.orders as orders
from oandapyV20.contrib.requests import LimitOrderRequest, MarketOrderRequest
from oandapyV20.contrib.factories import InstrumentsCandlesFactory
from datetime import datetime

from telegram.ext import Updater, CommandHandler, MessageHandler, Filters

ACCOUNT_ID = "101-002-17335250-001"
TOKEN = "97f13b231e46e12346b710983fa55121-fe68907269c0dabd676d6f9bd6ae21eb"


def update(message):
    """
        Update trade status.
    """
    # create oanda client
    client = API(access_token=TOKEN)
    messages = message.split('\n\n')

    trade = messages[0]
    pair = trade.split()[-1]
    first_pair, second_pair = pair.split('/')
    trading_pair = '%s_%s' % (first_pair, second_pair)
    # get trade_id for the corresponding trading pair
    trade_id = get_trade_id(trading_pair)

    params = {}
    for message in messages[1:]:
        if 'SL TO BE' in message.upper():
            # get trade entry price
            req = trades.TradeDetails(ACCOUNT_ID, tradeID=trade_id)
            trade_data = client.request(req)
            stop_loss = trade_data['trade']['price']
            params["stopLoss"] = {"price": stop_loss}
        elif message.startswith('SL'):
            stop_loss = message.split()[-1]
            params["stopLoss"] = {"price": stop_loss}
        elif message.startswith('TP'):
            take_profit = message.split()[-1]
            params["takeProfit"] = {"price": take_profit}
        elif 'CLOSE' in message.upper():
            close_percentage = int(message.split()[-1].strip('%'))
            req = trades.TradeDetails(ACCOUNT_ID, tradeID=trade_id)
            trade_data = client.request(req)
            current_units = abs(int(trade_data['trade']['currentUnits']))
            close_units = str(int(current_units * (close_percentage / 100)))
            data = {
                "units": close_units,
            }
            req = trades.TradeClose(accountID=ACCOUNT_ID, tradeID=trade_id,
                                    data=data)
            print('-----------------------------------------------------------\n\n')
            print('CLOSING PAIR: %s --> %s\n\n' % (first_pair, second_pair))
            print('UNITS CLOSED: %s' % close_units)
            print('\n\n-----------------------------------------------------------\n\n')
            response = client.request(req)
            # pprint(response)

    # send the trade update
    if params:
        print('-----------------------------------------------------------\n\n')
        print('UPDATING Pair: %s --> %s\n\n' % (first_pair, second_pair))
        pprint(params)
        print('\n\n-----------------------------------------------------------\n\n')
        req = trades.TradeCRCDO(ACCOUNT_ID, tradeID=trade_id, data=params)
        response = client.request(req)
        # pprint(response)


def close(trading_pair):
    """
    Close an open trade
    """
    client = API(access_token=TOKEN)

    trade_id = get_trade_id(trading_pair)
    close_percentage = 100
    req = trades.TradeDetails(ACCOUNT_ID, trade_ID=trade_id)
    trade_data = client.request(req)
    current_units = abs(int(trade_data['trade']['currentUnits']))
    close_units = str(int(current_units * (close_percentage / 100)))
    data = {
        "units": close_units,
    }
    req = trades.TradeClose(accountID=ACCOUNT_ID, tradeID=trade_id, data=data)
    response = client.request(req)


def buy(trading_pair, take_profit, stop_loss, units=10000, entry_price=None):
    """
        Execute a buy trade.
    """
    # create oanda client
    client = API(access_token=TOKEN)

    # parse trading messages
    #params = get_params_from_message(message)

    # create and execute trade
    ### BELOW IS USED FOR PARSING MESSAGE FROM TELEGRAM
    #units = params.get('units')
    #take_profit = params.get('take_profit')
    #stop_loss = params.get('stop_loss')
    #entry_price = params.get('entry_price')
    #trading_pair = params.get('trading_pair')

    take_profit = str(round(take_profit, 5))
    stop_loss = str(round(stop_loss, 5))

    max_units = get_max_availability_units(trading_pair)
    if int(units) > max_units:
        print('-----------------------------------------------------------\n\n')
        print('MAXIMUM AMOUNT OF UNITS EXCEEDED FOR THE ACCOUNT\n\n')
        print('ORDER ATTEMPT: %s \tMAX UNITS: %s' % (units, max_units))
        print('\n\n-----------------------------------------------------------\n\n')
        return

    print('-----------------------------------------------------------\n\n')
    print('TRADE PAIR FOUND: %s' % trading_pair)
    print('\n\n-----------------------------------------------------------\n\n')
    if entry_price:
        order = LimitOrderRequest(instrument=trading_pair,
                                  units=units, price=float(entry_price),
                                  takeProfitOnFill={'price': take_profit},
                                  stopLossOnFill={'price': stop_loss})

    else:
        order = MarketOrderRequest(instrument=trading_pair, units=units,
                                   takeProfitOnFill={'price': take_profit},
                                   stopLossOnFill={'price': stop_loss})

    _request = orders.OrderCreate(ACCOUNT_ID, data=order.data)
    response = client.request(_request)
    if response.get('ordercanceltransaction'):
        reason = response['ordercanceltransaction']['reason']
        print('-----------------------------------------------------------\n\n')
        print("trade order failed. reason <%s>" % reason)
        return

    order_transaction = response.get('orderFillTransaction')
    trade_id = order_transaction['id']

    # get trade info

    req = trades.TradeDetails(ACCOUNT_ID, tradeID=trade_id)
    trade_data = client.request(req)
    # pprint(trade_data)
    print('-----------------------------------------------------------')


def sell(trading_pair, take_profit, stop_loss, entry_price=None, units=-10000):
    """
        Execute a sell trade.
    """

    # create oanda client
    client = API(access_token=TOKEN)

    # parse trading messages
    #params = get_params_from_message(message)

    # create and execute trade
    ### BELOW IS USED FOR PARSING MESSAGE FROM TELEGRAM
    #_units = params.get('units')
    #units = float(_units) * -1
    #take_profit = params.get('take_profit')
    #stop_loss = params.get('stop_loss')
    #entry_price = params.get('entry')
    #trading_pair = params.get('trading_pair')

    take_profit = str(round(take_profit, 5))
    stop_loss = str(round(stop_loss, 5))
    units = units * -1

    max_units = get_max_availability_units(trading_pair)
    if int(units) > max_units:
        print('-----------------------------------------------------------\n\n')
        print('MAXIMUM AMOUNT OF UNITS EXCEEDED FOR THE ACCOUNT\n\n')
        print('ORDER ATTEMPT: %s \tMAX UNITS: %s' % (units, max_units))
        print('\n\n-----------------------------------------------------------\n\n')
        return

    print('-----------------------------------------------------------\n\n')
    print('TRADE PAIR FOUND: %s' % trading_pair)
    print('\n\n-----------------------------------------------------------\n\n')


    if entry_price:
        order = LimitOrderRequest(instrument=trading_pair,
                                  units=units, price=float(entry_price),
                                  takeProfitOnFill={'price': take_profit},
                                  stopLossOnFill={'price': stop_loss})

    else:
        order = MarketOrderRequest(instrument=trading_pair, units=units,
                                   takeProfitOnFill={'price': take_profit},
                                   stopLossOnFill={'price': stop_loss})

    _request = orders.OrderCreate(ACCOUNT_ID, data=order.data)
    response = client.request(_request)
    if response.get('orderCancelTransaction'):
        reason = response['orderCancelTransaction']['reason']
        print('-----------------------------------------------------------\n\n')
        print("TRADE ORDER FAILED. REASON <%s>" % reason)
        return

    order_transaction = response.get('orderFillTransaction')
    # if not order_transaction:
    #    import pdb;pdb.set_trace()
    trade_id = order_transaction['id']

    # get trade info

    req = trades.TradeDetails(ACCOUNT_ID, tradeID=trade_id)
    trade_data = client.request(req)
    # pprint(trade_data)
    print('-----------------------------------------------------------')


FUNCTIONS = {'BUY': buy,
             'SELL': sell,
             'UPDATE': update
             }


def get_account_info(accountID=ACCOUNT_ID):
    client = API(access_token=TOKEN)
    request = accounts.AccountDetails(accountID)
    response = client.request(request)
    return response


def get_margin_rate(trading_pair, accountID=ACCOUNT_ID):
    client = API(access_token=TOKEN)
    params = {
        'instruments': trading_pair,
    }
    request = accounts.AccountInstruments(accountID, params=params)
    response = client.request(request)
    marginRate = response['instruments'][0]['marginRate']
    return marginRate


def get_current_price(trading_pair, accountID=ACCOUNT_ID):
    client = API(access_token=TOKEN)
    params = {
        'instruments': trading_pair,
    }
    request = pricing.PricingInfo(accountID, params=params)
    response = client.request(request)
    prices = response.get('prices')
    asian_high = 0
    asian_low = None
    started = False
    trade_executed = False
    trade_type = None
    PIP = 0.0001
    TP = 35 * PIP
    SL = 100 * PIP
    if prices:
        try:

            current_price = prices[0]['bids'][0]['price']
            return current_price
        except Exception as e:
            print("ERROR FINDING PRICE FOR: <%s>" % trading_pair)
            print(e)
            raise (e)
    else:
        print("NO PRICES FOUND FOR: <%s>" % trading_pair)


def handle_message(update, context, units=10000):
    """
        Handle the incoming user messages coming from the channel
    """
    # get trading info from chat
    message = update.to_dict()['channel_post']['text']
    func_name = message.split()[0]

    func = FUNCTIONS[func_name]
    try:
        func(message)
    except Exception as e:
        print("Handling message <%s> failed" % e)


def get_max_availability_units(trading_pair, accountID=ACCOUNT_ID):
    current_price = get_current_price(trading_pair)
    account_info = get_account_info(accountID)
    margin_rate = get_margin_rate(trading_pair)
    margin_avail = account_info['account']['marginAvailable']
    account_currency = account_info['account']['currency']
    trade_currency = trading_pair.split('_')[-1]
    if account_currency != trade_currency:
        c = CurrencyConverter()
        margin_avail = c.convert(margin_avail, account_currency, trade_currency)

    max_units = int((float(margin_avail) / float(current_price)) / float(margin_rate))
    return max_units


def get_trade_id(trading_pair):
    client = API(access_token=TOKEN)
    params = {
        "instrument": trading_pair,
    }
    req = trades.TradesList(ACCOUNT_ID, params=params)
    trade = client.request(req)
    trade_id = trade['trades'][0]['id']
    return trade_id


def trade_execute(currency_pair):
    client = API(access_token=TOKEN)
    params = {
        "instruments": currency_pair,
    }
    request = pricing.PricingStream(accountID=ACCOUNT_ID, params=params)
    response = client.request(request)
    asian_high = 0
    asian_low = None
    started = False
    trade_executed = False
    trade_type = None
    PIP = 0.0001
    TP = 35 * PIP
    SL = 100 * PIP
    STARTING_TIMES = ['.*17\:[1][0]\:.*', '.*02\:[0-9][0-9]\:.*', '.*03\:[0-9][0-9]\:.*', '.*04\:[0-9][0-9]\:.*']
    REGEX_STARTING_TIMES = []
    for time in STARTING_TIMES:
        REGEX_STARTING_TIMES.append(re.compile(time))
    STOP_TIME = re.compile('.*17\:[3][0]\:.*')
    running = True
    while running:
        try:
            for ticks in response:
                try:
                    time = ticks['time']
                    price = ticks['bids'][0]['price']
                    if any(t.match(time) for t in REGEX_STARTING_TIMES) and not started:
                        print("STARTED TRACKING < 8:00 pm EST > on {}".format(time))
                        asian_high = 0
                        asian_low = None
                        started = True
                    if STOP_TIME.match(time) and started:
                        print("STOPPED TRACKING < 12:00 am EST > on {}".format(time))
                        print("STARTING TO TRADE WITH < HIGH: %s , LOW: %s >" % (asian_high, asian_low))
                        started = False

                    # start_trading(asian_high, asian_low)
                    # if '9:00:' in time and trade_executed == False:
                    #     trade_executed = False
                    #     asian_high = 0
                    #     asian_low = None

                    # this is where we update our Asian High and Asian Low
                    if started:
                        price_low = float(ticks['bids'][0]['price'])
                        price_high = float(ticks['asks'][0]['price'])
                        if price_high > asian_high:
                            asian_high = price_high
                            print("ASIAN HIGH: %s \t\t ASIAN LOW: %s" % (asian_high, asian_low))
                        if not asian_low or price_low < asian_low:
                            asian_low = price_low
                            print("ASIAN HIGH: %s \t\t ASIAN LOW: %s" % (asian_high, asian_low))


                    # if we're in trading hours and we have highs/lows we start trading
                    if not started and asian_low and not trade_executed:
                        price_low = float(ticks['bids'][0]['price'])
                        price_high = float(ticks['asks'][0]['price'])
                        if float(price_low) < float(asian_low):
                            print("BUY @ %s FOR $%s" % (time, asian_low))
                            print("*" * 80)
                            trade_executed = True
                            trade_type = "BUY"
                            func = FUNCTIONS[trade_type]
                            take_profit = float(asian_low) + TP
                            print(take_profit)
                            stop_loss = float(asian_low) - SL
                            print(stop_loss)
                            func(currency_pair, take_profit, stop_loss)
                        if float(price_high) > float(asian_high):
                            print("SELL @ {0} FOR ${1}".format(time, asian_high))
                            print("*" * 80)
                            trade_executed = True
                            trade_type = "SELL"
                            func = FUNCTIONS[trade_type]
                            take_profit = float(asian_high) - TP
                            print(take_profit)
                            stop_loss = float(asian_high) + SL
                            print(stop_loss)
                            func(currency_pair, take_profit, stop_loss)

                    # if we executed a trade, we need to now track to close it for profit
                    if trade_executed:
                        price_low = float(ticks['bids'][0]['price'])
                        price_high = float(ticks['asks'][0]['price'])
                        if trade_type == "BUY":
                            target_price = asian_low + TP
                            stop_loss = asian_low - SL
                            if float(price_low) > float(target_price):
                                print("TRADE CLOSED AT {0} ON {1}".format(target_price, time))
                                print("SL TO BE")
                                print("CLOSE HALF OF TRADE")
                                print("*" * 80)
                                close(currency_pair)
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                            elif float(price_low) == float(stop_loss):
                                print("SL HIT")
                                print('*' * 80)
                                close(currency_pair)
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                            # if '15:45:' in time and trade_executed == True:
                            #     print("TRADE CLOSED AT 10:45 EST")  # WITH {0} PIPS IN PROFIT"
                            #     trade_executed = False
                            #     asian_high = 0
                            #     asian_low = None
                        if trade_type == "SELL":
                            target_price = asian_high - TP
                            stop_loss = asian_high + SL
                            if float(price_high) < float(target_price):
                                print("TRADE CLOSED AT {0} ON {1}".format(target_price, time))
                                print("SL TO BE")
                                print("CLOSE HALF OF TRADE")
                                print("*" * 80)
                                trade_executed = False
                                close(currency_pair)
                                asian_high = 0
                                asian_low = None
                            elif float(price_high) == float(stop_loss):
                                print("SL HIT")
                                print('*' * 80)
                                close(currency_pair)
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                            # if '15:45:' in time and trade_executed == True:
                            #     print("TRADE CLOSED AT 10:45 EST")
                            #     print('*' * 80)
                            #     trade_executed = False
                            #     asian_high = 0
                            #     asian_low = None
                except Exception as e:
                    if 'bids' not in e.args:
                        print(e)
                    continue
        except Exception as e:
            response = client.request(request)
            client = API(access_token=TOKEN)





if __name__ == '__main__':
    trade_execute("GBP_AUD")