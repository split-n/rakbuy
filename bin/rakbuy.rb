require 'rakbuy'

username = ENV["RAKBUY_USERID"]
password = ENV["RAKBUY_PASSWORD"]

item_url = ARGV[0]

logger = Logger.new(STDOUT)

rak_buy = RakBuy.new(username, password, item_url, logger)
rak_buy.start_poll_and_buy
