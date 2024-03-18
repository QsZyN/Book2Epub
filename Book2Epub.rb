require 'nokogiri'
require 'gyazo'
require 'uri'

@suffix = ""
bookname = ""
project_name = ""

jsondata = {}
pages = []
jsondata['pages'] = pages

token = ENV['GYAZO_ACCESS_TOKEN']
gyazo = Gyazo::Client.new access_token: token

htmlfiles = ARGV.grep /\.html/i

#表紙
page = {}
lines = []
page['title'] = bookname
page['lines'] = lines
lines << bookname
lines << ""
lines << "`##{@suffix}`"
lines << "[📚]"
pages << page


(0..htmlfiles.length-1).each { |i|
    target_file_path = File.expand_path(htmlfiles[i])
    doc = File.open(target_file_path) { |f| Nokogiri::HTML(f) }

    def title(page)
        return "p#{page}##{@suffix}"
    end    

    #ルビの削除
    doc.css('ruby').each do |ruby|
        ruby.replace(ruby.at_css("rb").text)
    end

    #画像の置換
    doc.css('img').each do |img|
        image_path = File.expand_path(img.attribute('src'), File.dirname(target_file_path))
        STDERR.puts "gyazo #{image_path}"
        encodedPageName=URI.escape(title(i))
        res = gyazo.upload imagefile: image_path, referer_url: "https://scrapbox.io/#{project_name}/#{encodedPageName}", desc: "##{bookname}"
        gyazourl = res[:permalink_url]
        STDERR.puts gyazourl
        img.replace("[#{gyazourl}]")
        sleep 1
    end

    #段落を作る
    doc.css("p").each do |p|
        if p.content != ""
            p.content = "[　]#{p.content.gsub(/\A[[:space:]]+/, '')}\n"
        end
    end
    
    #空白と区別するために一時的にタグと置換
    doc.css("li").each do |li|
        li.content = "<li>#{li.content}"
    end

    page = {}
    lines = []
    page['title'] = title(i)
    lines << title(i)
    lines << "[#{title(i-1)}]"
    lines << ""
    doc.css("body").text.split(/\n/).each { |line|
    lines << line.sub(/\A[\s\u3000]+/, '').gsub(/<\/?li>/, ' ')
  }
    lines << ""
    lines << "[#{title(i+1)}]"
    lines << "Part of [#{bookname}]"

    #連続する改行を一行に変換
    page['lines'] = lines.chunk_while { |i, j| i == j }.map(&:first)
    pages << page
}

puts jsondata.to_json