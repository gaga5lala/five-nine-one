require 'rubygems'
require 'rest-client'
require 'nokogiri'
require 'json'
require 'telegram/bot'
require 'dotenv/load'

url = 'https://rent.591.com.tw/'
resp = RestClient.get(url)
cookie_str = resp.cookies.map{|k,v| "#{k}=#{v}"}.join('; ')

page = Nokogiri::HTML(resp)
contents = page.search("meta[name='csrf-token']").map { |n|
  n['content']
}
csrf_str = contents.first

search_url = 'https://rent.591.com.tw/home/search/rsList?is_format_data=1&is_new_list=1&type=1&regionid=1&section=5,3,1,4,2&searchtype=1&order=posttime&orderType=desc&multiRoom=2,3&rentprice=15000,25000&kind=1'

headers = {
  'X-Csrf-Token': csrf_str,
  'Cookie': cookie_str
}
resp = RestClient.get(search_url, headers = headers)

module Notifier
  class Telegram
    IFS="\n"
    def self.create(h)
      bot = ::Telegram::Bot::Client.new(ENV["TELEGRAM_TOKEN"])
      bot.api.send_message(chat_id: '228380306',
                           text: h.map{|k,v| "#{k}: #{v}"}.join(IFS))
    end
  end
end

KNOWN_HOUSES = "known_houses"
if !File.exists?(KNOWN_HOUSES)
  default = ["placeholder"]
  serialized_array = Marshal.dump(default)
  File.open(KNOWN_HOUSES, 'w') {|f| f.write(serialized_array) }
end

file = File.read(KNOWN_HOUSES)
known_houses = Marshal.load(file)

DETAIL_URL = "https://rent.591.com.tw/home/{house_id}"

result = JSON.parse(resp.body)
houses = result["data"]["data"]
houses.reject! {|h| known_houses.include?(h["post_id"]) }
houses.each do |house|
  message = {
    封面圖: house["photo_list"][0],
    標題: house["title"],
    網址: DETAIL_URL.gsub("{house_id}",house["post_id"].to_s),
    價錢: house["price"] + house["price_unit"],
    地址: house["section_name"] + house["street_name"] + house["location"],
    kindname: house["kind_name"],
    room_str: house["room_str"],
    坪數: house["area"],
    樓層: house["floor_str"],
    rent_tag: house["rent_tag"]
  }

  Notifier::Telegram.create(message)
  sleep 2
end

new_house_ids = houses.map { |h| h["post_id"] }

house_ids = known_houses + new_house_ids

serialized_array = Marshal.dump(house_ids)
File.open(KNOWN_HOUSES, 'w') {|f| f.write(serialized_array) }

unless new_house_ids.size.zero?
  system_message = {
    本次新增筆數: new_house_ids.size,
    total: house_ids.size,
    執行時間: Time.now
  }
  Notifier::Telegram.create(system_message)
end
