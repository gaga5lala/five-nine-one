require 'rest-client'
require 'nokogiri'

url = 'https://rent.591.com.tw/?regionid=1&section=5,7,3&searchtype=1&order=posttime&orderType=desc&multiRoom=2,3&rentprice=15000,25000'
resp = RestClient.get(url)
cookie_str = resp.cookies.map{|k,v| "#{k}=#{v}"}.join('; ')

page = Nokogiri::HTML(resp)
contents = page.search("meta[name='csrf-token']").map { |n|
  n['content']
}
# p page
p 'csrf=' + contents.first
csrf_str = contents.first

# TODO: use rest-client and remove comment
# generate by https://jhawthorn.github.io/curl-to-ruby/
require 'net/http'
require 'uri'
uri = URI.parse("https://rent.591.com.tw/home/search/rsList?is_format_data=1&is_new_list=1&type=1&regionid=1&section=5,3,1,4,2&searchtype=1&order=posttime&orderType=desc&multiRoom=2,3&rentprice=15000,25000&kind=1")
request = Net::HTTP::Get.new(uri)
request["Connection"] = "keep-alive"
request["Sec-Ch-Ua"] = "\"Chromium\";v=\"92\", \" Not A;Brand\";v=\"99\", \"Microsoft Edge\";v=\"92\""
request["Accept"] = "application/json, text/javascript, */*; q=0.01"
request["Dnt"] = "1"
request["X-Csrf-Token"] = csrf_str
request["Sec-Ch-Ua-Mobile"] = "?0"
request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36 Edg/92.0.902.55"
request["X-Requested-With"] = "XMLHttpRequest"
request["Sec-Fetch-Site"] = "same-origin"
request["Sec-Fetch-Mode"] = "cors"
request["Sec-Fetch-Dest"] = "empty"
request["Referer"] = "https://rent.591.com.tw/?regionid=1&section=5,3,1,4,2&searchtype=1&order=posttime&orderType=desc&multiRoom=2,3&rentprice=15000,25000&kind=1"
request["Accept-Language"] = "en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7"
request["Cookie"] = cookie_str
# request["Cookie"] = "webp=1; PHPSESSID=j1frcfnnvq86188d9r2c1b5it4; urlJumpIp=1; urlJumpIpByTxt=%E5%8F%B0%E5%8C%97%E5%B8%82; newUI=1; T591_TOKEN=j1frcfnnvq86188d9r2c1b5it4; tw591__privacy_agree=0; new_rent_list_kind_test=0; user_index_role=1; user_browse_recent=a%3A4%3A%7Bi%3A0%3Ba%3A2%3A%7Bs%3A4%3A%22type%22%3Bi%3A1%3Bs%3A7%3A%22post_id%22%3Bi%3A11346899%3B%7Di%3A1%3Ba%3A2%3A%7Bs%3A4%3A%22type%22%3Bi%3A1%3Bs%3A7%3A%22post_id%22%3Bi%3A11348984%3B%7Di%3A2%3Ba%3A2%3A%7Bs%3A4%3A%22type%22%3Bi%3A1%3Bs%3A7%3A%22post_id%22%3Bi%3A11361909%3B%7Di%3A3%3Ba%3A2%3A%7Bs%3A4%3A%22type%22%3Bi%3A1%3Bs%3A7%3A%22post_id%22%3Bi%3A11355893%3B%7D%7D; XSRF-TOKEN=eyJpdiI6IiszblwvbGtQcng1NjFrb0crMGFtUll3PT0iLCJ2YWx1ZSI6IklvNEd0SDAxUHBMdFhib2NcLzJCNmdGVWE3amQ0WTFyQktBdk5EbWpKV3VRRnBHWGRraGlRdTFXTVAwckMyd2Y3NHBnUmhKUlNqXC9WUHFmUXFnYnQ5aHc9PSIsIm1hYyI6ImUzMDgwZjVjYzQxNDU3YTBkZmM5MTY0ZTcwYWRkNzFiNGU3Y2JiNzNmYmRhNzRiMzY1ZGNjNDVlZTUyZDMyODkifQ%3D%3D; 591_new_session=eyJpdiI6Im5IVFl4bTVKdlVDdGJpK2E2T2YrU1E9PSIsInZhbHVlIjoiVnBGSUNDMlV4WmErK051UnhrbGdlNGJXRFlpZGxCckhJK1ZpTXpqbFV6dytrV21WMXVQZ2FlV280V1VPOHJKSjRscjJUN1VHbWNRamxKbml2WEErMXc9PSIsIm1hYyI6IjZmYjk1Y2E2ZmQ5ZGE3NDE5OWJhYmM2YjU2ZTkxZDIzNGU1ZmE2ZTRiNDgwODkxNjQ5NTJlODc0ZDFjYWZlZWUifQ%3D%3D"

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

######


require 'rubygems'
require 'json'
require 'telegram/bot'


require 'dotenv/load'

IFS="\n"

module Notifier
  class Telegram
    def self.create(h)
      bot = ::Telegram::Bot::Client.new(ENV["TELEGRAM_TOKEN"])
      bot.api.send_message(chat_id: '228380306',
                           text: h.map{|k,v| "#{k}: #{v}"}.join(IFS))
    end
  end
end

SEEN_HOUSE_FILE = "seen_houses"
if !File.exists?(SEEN_HOUSE_FILE)
  default = [999]
  serialized_array = Marshal.dump(default)
  File.open(SEEN_HOUSE_FILE, 'w') {|f| f.write(serialized_array) }
end

file = File.read(SEEN_HOUSE_FILE)
seen_houses = Marshal.load(file)
p "# 已經儲存 #{seen_houses.size} 筆房屋"

DETAIL_URL = "https://rent.591.com.tw/home/{house_id}"

result = JSON.parse(response.body)
houses = result["data"]["data"]
houses.reject! {|h| seen_houses.include?(h["post_id"]) }
houses.each do |house|
  # next if seen_houses.include?(house["post_id"])
  p house
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
    房東提供: house["condition"],
  }

  Notifier::Telegram.create(message)
  sleep 2
end

new_house_ids = houses.map { |h| h["post_id"] }

house_ids = seen_houses + new_house_ids

serialized_array = Marshal.dump(house_ids)
File.open(SEEN_HOUSE_FILE, 'w') {|f| f.write(serialized_array) }

unless new_house_ids.size.zero?
  system_message = {
    本次新增筆數: new_house_ids.size,
    total: house_ids.size,
    執行時間: Time.now
  }
  Notifier::Telegram.create(system_message)
end

