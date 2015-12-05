require 'rakbuy'
require 'time'

username = ENV["RAKBUY_USERID"]
password = ENV["RAKBUY_PASSWORD"]

item_url = ARGV[0]
time_str = ARGV[1]

logger = Logger.new(STDOUT)

rak_buy = RakBuy.new(username, password, item_url, logger)
rak_buy.empty_cart

if time_str
  time = Time.parse(time_str)
  rak_buy.start_poll_at(time)
else
  rak_buy.start_poll_and_buy
end
