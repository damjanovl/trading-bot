#!/usr/bin/env python

"""
Century Capital Bot
"""

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

from telegram.ext import Updater, CommandHandler, MessageHandler, Filters

import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import style

# setting graph style
style.use('fivethirtyeight')

# Enable logging
logging.basicConfig(filename='./trading_bot.log', filemode='w',
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO
                    )
console = logging.StreamHandler()
console.setLevel(logging.ERROR)
logging.getLogger("").addHandler(console)
# log = logging.getLogger('trading_bot')

ACCOUNT_ID = "101-002-16817565-001"
TOKEN = "80e8dca2b95c24f9e3de9abb79c1168d-9a4c1c7c93dc02b415b6398c94b969e9"


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


def get_historical_data(currency_pair, start, end=None, candle_stick="M5", count=2500):
    client = API(access_token=TOKEN)
    params = {
        "from": start,
        "granularity": candle_stick,
        "count": count
    }
    # candles = InstrumentsCandlesFactory(instrument=currency_pair, params=params)
    # import pdb;pdb.set_trace()
    # print(candles)
    with open(r"{}_{}.json".format(currency_pair, candle_stick), "w+") as OUT:
        # The factory returns a generator generating consecutive
        # requests to retrieve full history from date 'from' till 'to'
        for r in InstrumentsCandlesFactory(instrument=currency_pair, params=params):
            client.request(r)
            OUT.write(json.dumps(r.response.get('candles')))


def test_method(filename="GBP_AUD_M5.json"):
    with open(filename, "r") as IN:
        data = IN.read()

    historical_data = json.loads(data)
    asian_high = 0
    asian_low = None
    started = False
    trade_executed = False
    trade_type = None
    PIP = 0.0001
    TP = 35 * PIP
    SL = 100 * PIP
    for candle in historical_data:
        time = candle['time']
        if '01:00:' in time:
            print("STARTED TRACKING < 8:00 pm EST > on {}".format(time))
            started = True
            asian_high = 0
            asian_low = None
        if '05:00:' in time:
            print("STOPPED TRACKING < 12:00 am EST > on {}".format(time))
            print("STARTING TO TRADE WITH < HIGH: %s , LOW: %s >" % (asian_high, asian_low))
            started = False

            # start_trading(asian_high, asian_low)
        if '9:00:' in time and trade_executed == False:
            trade_executed = False
            asian_high = 0
            asian_low = None

        if started:
            price_low = float(candle['mid']['l'])
            price_high = float(candle['mid']['h'])
            if price_high > asian_high:
                asian_high = price_high
            if not asian_low or price_low < asian_low:
                asian_low = price_low

        if not started and asian_low:
            # import pdb;pdb.set_trace()
            price_low = float(candle['mid']['l'])
            price_high = float(candle['mid']['h'])
            if not trade_executed:
                if price_low < asian_low:
                    print("BUY @ %s FOR $%s" % (time, asian_low))
                    print("*" * 80)
                    trade_executed = True
                    trade_type = "BUY"
                if price_high > asian_high:
                    print("SELL @ {0} FOR ${1}".format(time, asian_high))
                    print("*" * 80)
                    trade_executed = True
                    trade_type = "SELL"

        if trade_executed:
            price_low = float(candle['mid']['l'])
            price_high = float(candle['mid']['h'])
            if trade_type == "BUY":
                target_price = asian_low + TP
                stop_loss = asian_low - SL
                if price_low > target_price:
                    print("TRADE CLOSED AT {0} ON {1}".format(target_price, time))
                    print("SL TO BE")
                    print("CLOSE HALF OF TRADE")
                    print("*" * 80)
                    trade_executed = False
                    asian_high = 0
                    asian_low = None
                if price_low == stop_loss:
                    print("SL HIT")
                    print('*' * 80)
                    trade_executed = False
                    asian_high = 0
                    asian_low = None
                if '15:45:' in time and trade_executed == True:
                    print("TRADE CLOSED AT 10:45 EST")  # WITH {0} PIPS IN PROFIT"
                    # .format(price_low + target_price))
                    trade_executed = False
                    asian_high = 0
                    asian_low = None
            if trade_type == "SELL":
                target_price = asian_high - TP
                stop_loss = asian_high + SL
                if price_high < target_price:
                    print("TRADE CLOSED AT {0} ON {1}".format(target_price, time))
                    print("SL TO BE")
                    print("CLOSE HALF OF TRADE")
                    print("*" * 80)
                    trade_executed = False
                    asian_high = 0
                    asian_low = None
                if price_high == stop_loss:
                    print("SL HIT")
                    print('*' * 80)
                    trade_executed = False
                    asian_high = 0
                    asian_low = None
                if '15:45:' in time and trade_executed == True:
                    print("TRADE CLOSED AT 10:45 EST")
                    print('*' * 80)
                    trade_executed = False
                    asian_high = 0
                    asian_low = None


def get_price(currency_pair):
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
    STARTING_TIMES = ['.*01\:[0-9][0-9]\:.*', '.*02\:[0-9][0-9]\:.*', '.*03\:[0-9][0-9]\:.*', '.*04\:[0-9][0-9]\:.*']
    REGEX_STARTING_TIMES = []
    for time in STARTING_TIMES:
        REGEX_STARTING_TIMES.append(re.compile(time))
    STOP_TIME = re.compile('.*05\:[0-9][0-9]\:.*')
    logging.info("*****************************STARTING BALLER BUDGETS BOT****************************")

    graph = plt.figure()
    plt.axis([0, 1000, 0, 1])
    i = 0
    running = True
    while running:
        try:
            logging.info("starting to fetch response")
            plt.show()
            for ticks in response:
                try:
                    price = ticks['bids'][0]['price']
                    time = ticks['time']
                    plt.plot(i, float(price))
                    plt.pause(0.05)
                    i += 1

                    # if current time is any of the start times we start tracking
                    if any(t.match(time) for t in REGEX_STARTING_TIMES) and not started:
                        print("STARTED TRACKING < 8:00 pm EST > on {}".format(time))
                        logging.info("STARTED TRACKING < 8:00 pm EST > on {}".format(time))
                        started = True
                        asian_high = 0
                        asian_low = None

                    # if current time is stop time we stop tracking
                    if STOP_TIME.match(time) and started:
                        print("STOPPED TRACKING < 12:00 am EST > on {}".format(time))
                        logging.info("STOPPED TRACKING < 12:00 am EST > on {}".format(time))
                        print("STARTING TO TRADE WITH < HIGH: %s , LOW: %s >" % (asian_high, asian_low))
                        logging.info("STARTING TO TRADE WITH < HIGH: %s , LOW: %s >" % (asian_high, asian_low))
                        started = False

                    # if '09:00:' in time and not trade_executed:
                    #     asian_high = 0
                    #     asian_low = None
                    #     started = False

                    # this is where we update our Asian High and Asian Low
                    if started:
                        price_low = float(ticks['bids'][0]['price'])
                        price_high = float(ticks['asks'][0]['price'])
                        if price_high > asian_high:
                            asian_high = price_high
                            print("ASIAN HIGH: %s \t\t ASIAN LOW: %s" % (asian_high, asian_low))
                            logging.info("ASIAN HIGH: %s \t\t ASIAN LOW: %s" % (asian_high, asian_low))
                        if not asian_low or price_low < asian_low:
                            asian_low = price_low
                            print("ASIAN HIGH: %s \t\t ASIAN LOW: %s" % (asian_high, asian_low))
                            logging.info("ASIAN HIGH: %s \t\t ASIAN LOW: %s" % (asian_high, asian_low))

                    # if we're in trading hours and we have highs/lows we start trading
                    if not started and asian_low and not trade_executed:
                        price_low = float(ticks['bids'][0]['price'])
                        price_high = float(ticks['asks'][0]['price'])
                        if float(price_low) < float(asian_low):
                            print("BUY @ %s FOR $%s" % (time, asian_low))
                            logging.info("BUY @ %s FOR $%s" % (time, asian_low))
                            print("*" * 80)
                            trade_executed = True
                            trade_type = "BUY"
                        if float(price_high) > float(asian_high):
                            print("SELL @ {0} FOR ${1}".format(time, asian_high))
                            logging.info("SELL @ {0} FOR ${1}".format(time, asian_high))
                            print("*" * 80)
                            trade_executed = True
                            trade_type = "SELL"

                    # if we executed a trade, we need to now track to close it for profit
                    if trade_executed:
                        price_low = float(ticks['bids'][0]['price'])
                        price_high = float(ticks['asks'][0]['price'])
                        if trade_type == "BUY":
                            target_price = asian_low + TP
                            stop_loss = asian_low - SL
                            if float(price_low) > float(target_price):
                                print("TRADE CLOSED AT {0} ON {1}".format(target_price, time))
                                logging.info("TRADE CLOSED AT {0} ON {1}".format(target_price, time))
                                print("SL TO BE")
                                print("CLOSE HALF OF TRADE")
                                print("*" * 80)
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                            if float(price_low) == float(stop_loss):
                                print("SL HIT")
                                print('*' * 80)
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                            if '15:45:' in time and trade_executed == True:
                                print("TRADE CLOSED AT 10:45 EST")  # WITH {0} PIPS IN PROFIT"
                                logging.info("TRADE CLOSED AT 10:45 EST")  # WITH {0} PIPS IN PROFIT"
                                # .format(price_low + target_price))
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                        if trade_type == "SELL":
                            target_price = asian_high - TP
                            stop_loss = asian_high + SL
                            if float(price_high) < float(target_price):
                                print("TRADE CLOSED AT {0} ON {1}".format(target_price, time))
                                logging.info("TRADE CLOSED AT {0} ON {1}".format(target_price, time))
                                print("SL TO BE")
                                print("CLOSE HALF OF TRADE")
                                print("*" * 80)
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                            if float(price_high) == float(stop_loss):
                                print("SL HIT")
                                print('*' * 80)
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                            if '15:45:' in time and trade_executed == True:
                                print("TRADE CLOSED AT 10:45 EST")
                                logging.info("TRADE CLOSED AT 10:45 EST")
                                print('*' * 80)
                                trade_executed = False
                                asian_high = 0
                                asian_low = None
                        #logging.debug("TIME: <%s> \tPRICE: <%s>\n" % (time, price))
                except Exception as e:
                    # logging.exception(e)
                    continue
        except Exception as e:
            logging.exception(e)
            response = client.request(request)



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


def get_params_from_message(message):
    """
        Parse message into a dictionary containing trade data
    """
    trading_data = {'units': 10000}
    for line in message.split('\n\n'):
        if 'BUY' in line or 'SELL' in line:
            # get trade action (buy/sell)
            if line.startswith('BUY'):
                trading_data['action'] = 'BUY'
            if line.startswith('SELL'):
                trading_data['action'] = 'SELL'
            # get trade action (buy/sell)
            pair = line.split()[-1]
            first_pair, second_pair = pair.split('/')
            trading_data['trading_pair'] = '%s_%s' % (first_pair, second_pair)
        if 'ENTRY' in line:
            entry_price = line.split()[-1]
            trading_data['entry_price'] = entry_price
        if line.startswith('TP'):
            take_profit = line.split()[-1]
            trading_data['take_profit'] = take_profit
        if line.startswith('SL'):
            stop_loss = line.split()[-1]
            trading_data['stop_loss'] = stop_loss
        if line.startswith('UNITS'):
            units = line.split()[-1]
            trading_data['units'] = units

    return trading_data


def buy(message):
    """
        Execute a buy trade.
    """
    # create oanda client
    client = API(access_token=TOKEN)

    # parse trading messages
    params = get_params_from_message(message)

    # create and execute trade
    units = params.get('units')
    take_profit = params.get('take_profit')
    stop_loss = params.get('stop_loss')
    entry_price = params.get('entry_price')
    trading_pair = params.get('trading_pair')
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


def sell(message, entry_price=None, units=10):
    """
        Execute a sell trade.
    """
    # create oanda client
    client = API(access_token=TOKEN)

    # parse trading messages
    params = get_params_from_message(message)

    # create and execute trade
    _units = params.get('units')
    units = float(_units) * -1
    take_profit = params.get('take_profit')
    stop_loss = params.get('stop_loss')
    entry_price = params.get('entry')
    trading_pair = params.get('trading_pair')
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


def main():
    """Start the bot."""
    # Create the Updater and pass it your bot's token.
    # Make sure to set use_context=True to use the new context based callbacks
    # Post version 12 this will no longer be necessary
    updater = Updater("1383917339:AAFfv4iUZ-44Y1HgZDArcH4X1F9Ub-jO_C4", use_context=True)

    # Get the dispatcher to register handlers
    dp = updater.dispatcher

    # Begin handling the messages from the Century Capital Channel
    dp.add_handler(MessageHandler(Filters.text & ~Filters.command, handle_message))

    # Start the Bot
    updater.start_polling()

    # Run the bot until you press Ctrl-C or the process receives SIGINT,
    # SIGTERM or SIGABRT. This should be used most of the time, since
    # start_polling() is non-blocking and will stop the bot gracefully.
    updater.idle()


if __name__ == '__main__':
    get_price("GBP_AUD")
    # get_historical_data("GBP_AUD", "2020-01-01T00:00:00Z")
    # test_method()
    # main()
