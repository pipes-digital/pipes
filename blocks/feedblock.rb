
require 'nokogiri'

class Feedblock < Block
    def process(inputs)
        if self.options[:userinput]
            url = self.options[:userinput]
        end

        if self.options[:userinputs]
            url = self.options[:userinputs][0]
        end

        if url.empty?
            return '<rss version="2.0"><channel><title>No Feed provided</title><link></link><description>The feed block was given no url</description></channel></rss>'
        end 

        url = detectHiddenFeeds(url)
        
        downloader = Downloader.new
        begin
            page = downloader.get(url)
        rescue TypeError => te
            # the input was probably no real url
            return '<rss version="2.0"><channel><title>Feed download failed</title><link></link><description>The feed block could not download this, did you enter a real url?</description></channel></rss>'
        end

        if page[0..50].include?('<html') || page[0..50].include?('<HTML')
            # we got a page link instead of a feed, but we can try to look for a linked feed
            doc = Nokogiri::HTML(page)
            origUrl = URI.parse(URI.escape(url))
            begin
                url = doc.css('link[rel="alternate"]').first['href']
            rescue NoMethodError => nme
                # we could find no feed! To not die later on we will return a minimal error feed
                return '<rss version="2.0"><channel><title>Feed not found</title><link></link><description>The feed block could find no feed under the given url</description></channel></rss>'
            end
            if (! url.include?('http://') && ! url.include?('https://') )
                url = "#{origUrl.scheme}://#{origUrl.host}/" + url
            end
            return downloader.get(url)
        else
            return page
        end
    end

    # detect feeds for important sites that don't advertise them, youtube so far
    def detectHiddenFeeds(url)
        if (url.include?('www.youtube.com'))
            if (url.include?('www.youtube.com/channel'))
                feedid = url.scan(/channel\/[^\/]+/).first.gsub('channel/', '')
                url = 'https://www.youtube.com/feeds/videos.xml?channel_id=' + feedid
            end
            if (url.include?('www.youtube.com/c/'))
                htmlPage = Downloader.new.get(url)
                canoncialPage = htmlPage.scan(/<link rel="canonical" href="(.+)"/).first.first
                feedid = canoncialPage.scan(/channel\/[^\/]+/).first.gsub('channel/', '')
                url = 'https://www.youtube.com/feeds/videos.xml?channel_id=' + feedid
            end
            if (url.include?('www.youtube.com/user'))
                feedid = url.scan(/user\/[^\/]+/).first.gsub('user/', '')
                url = 'https://www.youtube.com/feeds/videos.xml?user=' + feedid
            end
            if (url.include?('www.youtube.com/playlist?list') || (url.include?('www.youtube.com/watch?') && url.include?('list=')))
                feedid = url.scan(/list=[^\/]+/).first.gsub('list=', '')
                url = 'https://www.youtube.com/feeds/videos.xml?playlist_id=' + feedid
            end
        end
        return url
    end

end