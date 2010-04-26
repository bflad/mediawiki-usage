require 'rubygems'
require 'mysql2'
require 'openssl'
require 'open-uri'
require 'hpricot'
require 'time'
require 'yaml'
require 'digest/md5'

MEDIA_WIKI_URL = "https://mediawiki.wharton.upenn.edu/wcit/Special:RecentChanges"
CONFIG = YAML.load_file("config/database.yml") if File.exists?("config/database.yml")
DB = Mysql2::Client.new(:host => CONFIG['host'], :username => CONFIG['username'], :password => CONFIG['password'], :database => CONFIG['database'])
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def get_page(li)
  (li/"a").each do |link|
    return link.inner_html if not link.inner_html == "diff" and not link.inner_html == "hist"
  end
end

def get_changed_at(day, li)
  Time.parse("#{day} #{li.inner_html.scan(/;(\d\d:\d\d)/)[0][0]}")
end

def get_char_changes(li)
  (li/"[@class~='mw-plusminus-neg']|[@class~='mw-plusminus-pos']|[@class~='mw-plusminus-null']").inner_html.scan(/[,\d]+/)[0].gsub(/,/, "").to_i
end

def get_editor(li)
  (li/"[@class~='mw-userlink']").inner_html
end

task :cron do
  doc = Hpricot(open(MEDIA_WIKI_URL))
  (doc/"h4").each do |header|
    day = header.to_plain_text
    (header.next_sibling/"li").each do |change|
      first_link = (change/"a")[0].inner_html

      if first_link == "diff" or first_link == "hist"
        page = get_page(change)
        changed_at = get_changed_at(day, change)
        char_changes = get_char_changes(change)
        editor = get_editor(change)
        hash = Digest::MD5.hexdigest("#{page}#{changed_at}#{char_changes}#{editor}")

        begin
          DB.query("INSERT INTO changes (hash,page,changed_at,char_changes,editor) VALUES ('%s','%s','%s',%d,'%s')" % [
            hash, DB.escape(page), changed_at.strftime('%Y-%m-%d %H:%M:%S'), char_changes, DB.escape(editor)
          ])
        rescue Mysql2::Error => e
          # Ignore duplicate inserts
        end
      end
    end
  end
end
