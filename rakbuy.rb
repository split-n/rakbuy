require 'mechanize'
require 'logger'

class RakBuy
  def initialize(username, password, item_url, logger)
    @agent = Mechanize.new
    @item_url = item_url
    @stop_poll = false
    @logger = logger

    login(username, password)
  end

  def empty_cart
    cart_page = @agent.get("https://basket.step.rakuten.co.jp/rms/mall/bs/cartall/")
    if cart_page.uri.to_s.include?("cartempty")
      @logger.info("Cart is already empty.")
      return
    end

    delete_btns = cart_page.search('td[width="40"][bgcolor="#ffffff"] > font[size="-1"] > a')
    delete_links = delete_btns.map{|a| a.attribute("href").value }
    delete_links.each do |link|
      sleep 0.3
      @agent.get link
      @logger.info("A cart item deleted.")
    end

    @logger.info("Cart is (maybe) empty.")
  end

  # 購入可能になったらreturn true
  def start_poll
    return !!start_poll_page
  end

  def start_poll_and_buy
    page = start_poll_page
    if page
      buy(page)
    end
  end

  def stop_poll
    @stop_poll = true
  end

  private

  def login(username, password)
    page = @agent.get("https://www.rakuten.co.jp/myrakuten/login.html")
    form = page.form_with(name: "login")
    form.field_with(name: "u").value = username
    form.field_with(name: "p").value = password

    logged_page = form.submit
    raise StandardError, "Login failed" if logged_page.search(".mr-name").empty?
    @logger.info("Logged.")
  end

  # if can_buy, return page. if stopped, return nil.
  def start_poll_page
    loop do
      if @stop_poll
        @stop_poll = false
        return nil
      end

      page = @agent.get(@item_url)
      if can_buy(page)
        return page
      end
    end
  end

  def can_buy(item_page)

  end

  # return: succeed?
  def buy_item(item_page)

  end
end

username = ARGV[0]
password = ARGV[1]
item_url = ARGV[2]

logger = Logger.new(STDOUT)

rak_buy = RakBuy.new(username, password, item_url, logger)
rak_buy.empty_cart
#rak_buy.start_poll_and_buy
