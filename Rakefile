require 'sqlite3'
require 'dm-core'
require 'open-uri'
require 'hpricot'
require 'time'
require 'digest/md5'
require 'lib/change'

MEDIA_WIKI_URL = "https://mediawiki.wharton.upenn.edu/wcit/Special:RecentChanges"
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/usage.db")
DataMapper.auto_upgrade!

def get_topic(li)
  (li/"a").each do |link|
    return link.inner_html if not link.inner_html == "diff" and not link.inner_html == "hist"
  end
end

def get_changed_at(day, li)
  Time.parse("#{day} #{li.inner_html.scan(/;(\d\d:\d\d)/)[0][0]}")
end

def get_line_changes(li)
  (li/"[@class~='mw-plusminus-neg']|[@class~='mw-plusminus-pos']|[@class~='mw-plusminus-null']").inner_html.scan(/[,\d]+/)[0].gsub(/,/, "")
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
        topic = get_topic(change)
        changed_at = get_changed_at(day, change)
        line_changes = get_line_changes(change)
        editor = get_editor(change)
        change_hash = Digest::MD5.hexdigest("#{topic}#{changed_at}#{line_changes}#{editor}")
        
        params = {:change => {
          :change_hash => change_hash,
          :topic => topic,
          :changed_at => changed_at,
          :line_changes => line_changes,
          :editor => editor
        }}
        begin 
          change = Change.new(params[:change])
          change.save
        rescue DataObjects::IntegrityError => e
          # Ignore duplicate inserts
        end
      end
    end
  end
end

