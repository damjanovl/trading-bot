#!/usr/bin/env python

"""
Century Capital Bot
"""

import logging
from pprint import pprint

from currency_converter import CurrencyConverter
from oandapyV20 import API
import oandapyV20.endpoints.trades as trades
import oandapyV20.endpoints.pricing as pricing
import oandapyV20.endpoints.accounts as accounts
import oandapyV20.endpoints.orders as orders
from oandapyV20.contrib.requests import LimitOrderRequest, MarketOrderRequest

from telegram.ext import Updater, CommandHandler, MessageHandler, Filters

# Enable logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO
)

logger = logging.getLogger(__name__)

ACCOUNT_ID = "101-002-16817565-001"
TOKEN = "2606f3c9bc46f3701e72db6568de9ecb-20ef1f372929b4acee62d5646d2fc6f1"


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
    if prices:
        try:
            current_price = prices[0]['bids'][0]['price']
            return current_price
        except Exception as e:
            print("ERROR FINDING PRICE FOR: <%s>" % trading_pair)
            print(e)
            raise(e)
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
            #pprint(response)

    # send the trade update
    if params:
        print('-----------------------------------------------------------\n\n')
        print('UPDATING Pair: %s --> %s\n\n' % (first_pair, second_pair))
        pprint(params)
        print('\n\n-----------------------------------------------------------\n\n')
        req = trades.TradeCRCDO(ACCOUNT_ID, tradeID=trade_id, data=params)
        response = client.request(req)
        #pprint(response)


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
        if  line.startswith('TP'):
            take_profit = line.split()[-1]
            trading_data['take_profit'] = take_profit
        if  line.startswith('SL'):
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

    _request = orders.OrderCreate(ACCOUNT_ID, data = order.data)
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
    #pprint(trade_data)
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

    _request = orders.OrderCreate(ACCOUNT_ID, data = order.data)
    response = client.request(_request)
    if response.get('orderCancelTransaction'):
        reason = response['orderCancelTransaction']['reason']
        print('-----------------------------------------------------------\n\n')
        print("TRADE ORDER FAILED. REASON <%s>" % reason)
        return

    order_transaction = response.get('orderFillTransaction')
    #if not order_transaction:
    #    import pdb;pdb.set_trace()
    trade_id = order_transaction['id']

    # get trade info

    req = trades.TradeDetails(ACCOUNT_ID, tradeID=trade_id)
    trade_data = client.request(req)
    #pprint(trade_data)
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
    main()
