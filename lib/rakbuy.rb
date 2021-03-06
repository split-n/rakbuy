require "rakbuy/version"

require 'mechanize'
require 'logger'

class RakBuy
  def initialize(username, password, item_url, logger)
    @agent = Mechanize.new
    @item_url = item_url
    @stop_poll = false
    @logger = logger

    @username = username
    @password = password

    login(username, password)
  end

  def empty_cart
    cart_page = @agent.get("https://basket.step.rakuten.co.jp/rms/mall/bs/cartall/")
    if cart_empty?(cart_page)
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

  def start_poll_and_buy
    page = start_poll_page
    if page
      buy_item(page)
    end
  end

  def start_poll_at(time)
    poll_page_once
    @logger.info("Sleep until #{time}.")
    sleep_time = (time - Time.now) - 30
    sleep sleep_time
    @logger.info("Start polling in 30 sec.")
    sleep 29

    start_poll_and_buy
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
      page = poll_page_once
      return page if page

      sleep 0.2
    end
  end

  def poll_page_once
      page = @agent.get(@item_url)

      check_item_page(page)
      if can_buy(page)
        @logger.info("Poll result: CAN BUY")
        return page
      else
        @logger.info("Poll result: can't buy")
        return false
      end
  end

  def can_buy(item_page)
    before_sale = item_page.search(".preSalesMsg").empty?
    has_buy_form = buy_forms(item_page).length == 1
    before_sale && has_buy_form
  end

  # return: succeed?
  def buy_item(item_page)
    cart_page = enter_item_to_cart(item_page)

    cart_order_forms = cart_page.forms_with(action: "https://basket.step.rakuten.co.jp/rms/mall/bs/cart/set")
    if cart_order_forms.length > 1
      raise StandardError, "2 or more shops in cart."
    end

    order_page = cart_order_forms.first.submit

    if order_page.uri.to_s.end_with?("bs/orderfrom/")
      login_form = order_page.form_with(name:"login")
      login_form.field_with(name: "u").value = @username
      login_form.field_with(name: "p").value = @password
      order_page = login_form.submit
      @logger.info("Logged in orderfrom")
    end

    unless order_page.uri.to_s.end_with?("rms/mall/bs/confirmorderquicknormalize/")
      raise StandardError, "not order page"
    end

    order_form = order_page.form_with(id: "mainForm")
    submit_button = order_form.button_with(value: "注文を確定する")
    if(false) # safe for debugging
      ordered_page = order_form.click_button(submit_button)
      if ordered_page.title.include?("注文受付")
        @logger.info("Maybe bought item.")
      else
        @logger.info("Order send, but page title is #{ordered_page.title}")
      end
      binding.pry
    else
      binding.pry
    end
  end

  # return cart_page if succeed
  def enter_item_to_cart(item_page)
    buy_form = buy_forms(item_page).first

    cart_page = buy_form.submit
    if cart_empty?(cart_page)
      raise StandardError, "Failed to add item to cart."
    end

    cart_page
  end

  def cart_empty?(cart_page)
    cart_page.uri.to_s.include?("cartempty")
  end

  def check_item_page(item_page)
    buy_forms = buy_forms(item_page)

    if buy_forms.length == 0
      raise StandardError, "No item found."
    end

    if buy_forms.length > 1
      raise StandardError, "2 or more items found."
    end
  end

  def buy_forms(item_page)
    item_page.forms_with(method: "POST").select{|f|
      f.button_with(value: "買い物かごに入れる") != nil ||
      f.button_with(value: "お買い物かごに入れる") != nil
    }
  end
end
