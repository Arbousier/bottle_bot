require 'rubygems'
require "bundler/setup"

require 'cinch'
require 'net/http'
require "uri"
require "nokogiri"
require 'json'


QUOTES = YAML::load( File.open( 'quotes.yml' ) )
CONFIG = YAML::load( File.open( 'settings.yml' ) )
MY_NAME = CONFIG["nick"]
MJOLK_USERNAME = CONFIG["mjolk_username"]
MJOLK_PASSWORD = CONFIG["mjolk_password"]
GOOGLESEARCH_API = CONFIG["google_api"]
SERVER = CONFIG["server"]
CHANNEL = '#' + CONFIG["channel"]

bot = Cinch::Bot.new do
  configure do |c|
    c.server = SERVER
    c.nick = MY_NAME
    c.channels = [CHANNEL]
  end
  
  helpers do
    def google(query)
      begin
        google_payload = "/customsearch/v1?key=#{GOOGLESEARCH_API}&cx=013036536707430787589:_pqjad5hr1a&q=#{query}&alt=json"
        host = "www.googleapis.com"
        port = "443"

        req = Net::HTTP::Get.new(google_payload)
        httpd = Net::HTTP.new(host, port)
        httpd.use_ssl = true
        response = httpd.request(req)
        json_res = JSON.parse(response.body)
        first_result = json_res["items"][0]
        title = first_result["title"]
        desc = first_result["snippet"]
        link = first_result['link']
        return "#{title} #{desc} (#{link})"
      rescue
        "no result found"
      end
    end

    def logger(message)
      log_file = "log.log"
      File.open(log_file, 'w') {} unless File.exist?(log_file)
      File.open(log_file, 'a') do |log|
        log.puts(message)
      end
    end

    def a_quote
      i = rand(QUOTES.count) - 1
      i = 0 if i < 0
      quote_author = QUOTES.keys[i]
      size = QUOTES[quote_author].count
      i = rand(size - 1)
      i = 0 if i < 0
      quote = QUOTES[quote_author][i]
      return quote + "-- #{quote_author}"
    end

    def post_url(url,description,tags)
      host = "www.mjolk.net"
      port = "443"
      payload = "/v1/posts/add?url=#{url}&description=#{description}&tags=#{tags}"
      httpd = Net::HTTP.new(host, port)
      req = Net::HTTP::Post.new(payload)
      httpd.use_ssl = true
      httpd.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = httpd.request(req)

      answer = Nokogiri::XML(response.body)
      logger(answer.inspect)
    end
  end

  on :message, "#{MY_NAME}: hello" do |m|
    m.reply "Hello, #{m.user.nick}"
  end

  on :message, "#{MY_NAME}: quote" do |m|
    m.reply a_quote
  end

  on :message, /^!mjolk (.+)/ do |m, query|
    data = query.split("#")
    url = data[0]
    desc = data[1]
    tags = data[2] + ",#{m.user}"
    post_url(url,desc,tags)
  end

  on :message, /^!help/ do |m|
    #m.reply("!mjolk http://www.alink.com#a description of the link#tag1,tag2,tag3")
    m.reply("!quote")
    m.reply("!google a search")
  end

  on :message, /^!google (.+)/ do |m, query|
    m.reply google(query)
  end

  on :message, /cat/ do |m|
    m.reply "meeeowww"
  end

  on :message, /dog/ do |m|
    m.reply "woof"
  end

  on :message, /github/ do |m|
    m.reply "happy coders"
  end

  on :message, /lol/ do |m|
    m.reply a_quote
  end

  on :message, /microsoft/ do |m|
    m.reply "the Dark lord Sauron lives at microsoft"
  end

  on :message, /apple/ do |m|
    m.reply "kaki dehors, caca dedans -- Coluche"
  end

  on :message, /IE/ do |m|
    m.reply "sale sale sale, bad bad bad"
  end

  on :message, /ruby/ do |m|
    m.reply "yabon ruby"
  end

  on :message, /python/ do |m|
    m.reply "marmoutte: un client pour toi"
  end
end

bot.start