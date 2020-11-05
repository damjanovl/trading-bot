# trading-bot
TradingView + Oanda trading bot

# Installation

git clone https://github.com/damjanovl/trading-bot
cd trading-bot/
python3 -m venv venv/
venv/bin/pip install -r requirements.txt

# To run

venv/bin/python client.py


Example Commands:

```
SELL XAU/USD

SL 1925.40

TP 1880
```
```
BUY STOP XAU/USD

ENTRY 1899

TP 1910

SL 1890

UNITS 140
```
