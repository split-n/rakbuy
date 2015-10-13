require 'rakbuy'

username = ARGV[0]
password = ARGV[1]
item_url = ARGV[2]

logger = Logger.new(STDOUT)

rak_buy = RakBuy.new(username, password, item_url, logger)
rak_buy.start_poll_and_buy
