require 'rubygems'
require 'simple-rss'
require 'open-uri'
require 'tty-screen'
require 'yaml'
require 'tty-pager'

require 'pastel'
pastel = Pastel.new

require 'byebug'

width = TTY::Screen.width

yaml = YAML.load_file('channels.yml')
videos = []
threads = []

Video = Struct.new(:title, :channel_title, :link, :timestamp)

yaml['channels'].each do |channel|
  threads << Thread.new do
    if channel.class == String
      channel_id = channel
      inclusion = nil
      exclusion = nil
    else
      channel_id = channel['id']
      inclusion = channel['include']
      exclusion = channel['exclude']
    end

    url = "https://www.youtube.com/feeds/videos.xml?channel_id=#{channel_id}"
    rss = SimpleRSS.parse URI.open(url)

    rss.channel.items.each do |video|
      next if inclusion && !video.title.include?(inclusion)
      next if exclusion && video.title.include?(exclusion)

      videos << Video.new(video.title,
        rss.channel.title,
        video.link,
        video.published.to_datetime)
    end
  end
end

threads.each(&:join)

TTY::Pager.page do |pager|
  videos.sort_by{|v| v.timestamp}.reverse.each do |video|
    pager.write "#{pastel.bold(video.channel_title)}\n"
    pager.write " #{video.title}\n"
    pager.write " #{video.link}\n"
    pager.write " #{video.timestamp.strftime('%c')}\n"
    pager.write "-" * width + "\n"
  end
end
