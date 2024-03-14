require 'nokogiri'
require 'gyazo'
require 'uri'

@prefix = ""
bookname = ""

jsondata = {}
pages = []
jsondata['pages'] = pages

token = ENV['GYAZO_ACCESS_TOKEN']
gyazo = Gyazo::Client.new access_token: token

htmlfiles = ARGV.grep /\.html/i

(0..htmlfiles.length-1).each { |i|
    target_file_path = File.expand_path(htmlfiles[i])
    doc = File.open(target_file_path) { |f| Nokogiri::HTML(f) }

    #ルビの削除
    doc.css('ruby').each do |ruby|
        ruby.replace(ruby.at_css("rb").text)
    end

    page = {}
    lines = []
    def title(page)
        return "p#{page}##{@prefix}"
    end    
    page['title'] = title(i)
    page['lines'] = lines
    lines << title(i)
    lines << "[#{title(i-1)}]"
    doc.css("p").each do |node|
        if node.css("img").empty?
            lines << node.text.gsub(/　+/, '[\0]')
        else
            image_path = File.expand_path(node.css("img").attribute('src'), File.dirname(target_file_path))
            STDERR.puts "gyazo #{image_path}"
            encodedPageName=URI.escape(title(i))
            ruby.replace(ruby.at_css("rb").text)
            # res = gyazo.upload imagefile: image_path, referer_url: "https://scrapbox.io//#{encodedPageName}", desc: bookname
            # gyazourl = res[:permalink_url]
            # STDERR.puts gyazourl
            # lines << "[#{gyazourl}]"
        end
    end
    lines << "[#{title(i+1)}]"
    lines << ""
    lines << "Part of[#{bookname}]"
    pages << page
}

puts jsondata.to_json