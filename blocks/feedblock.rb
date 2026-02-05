require 'nokogiri'
require 'addressable/uri'
require 'rss'
require 'feedparser'

class Feedblock < Block
    def process(inputs)
        if self.options[:userinput]
            url = self.options[:userinput]
        end

        if self.options[:userinputs]
            url = self.options[:userinputs][0]
        end

        if url.empty?
            return self.errorFeed('No Feed provided', 'The feed block was given no url')
        end 

        url = detectHiddenFeeds(url)
        
        downloader = Downloader.new
        begin
            page = downloader.get(url)
        rescue TypeError => te
            # the input was probably no real url
            return self.errorFeed('Feed download failed', 'The feed block could not download this, did you enter a real url?')
        end

        if page.empty?
            return self.errorFeed('Feed download failed', 'The feed block could not download this, is the target URL up?')
        end

        if page[0..50].include?('<html') || page[0..50].include?('<HTML')
            # we got a page link instead of a feed, but we can try to look for a linked feed
            doc = Nokogiri::HTML(page)
            origUrl = URI.parse(Addressable::URI.parse(url))
            begin
                url = doc.css('link[rel="alternate"]').first['href']
            rescue NoMethodError => nme
                # we could find no feed! To not die later on we will return a minimal error feed
                return self.errorFeed('Feed not found', 'The feed block could find no feed under the given url.')
            end
            if (! url.include?('http://') && ! url.include?('https://') )
                url = "#{origUrl.scheme}://#{origUrl.host}/" + url
            end
            feedContent = downloader.get(url)
        else
            feedContent = page
        end
        
        # Two-ponged approach: For better compatibility we start with the normalized feed gem
        feed = FeedParser::Parser.parse(feedContent)
        # But we also try to get a regular ruby version, as that one has more fields
        begin
            rubyFeed = RSS::Parser.parse(feedContent)
        rescue
            warn "Could not parse ruby feed for " + url
        end

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = feed.updated&.to_s
            maker.channel.title = feed.title
            if (feed.url && feed.url != '')
                maker.channel.link = feed.url
            else
                if (feed.feed_url && feed.feed_url != '')
                    maker.channel.link = feed.feed_url
                else
                    maker.channel.link = ' ' # the rss won't get emitted if link is empty
                end
            end
            if (feed.summary && feed.summary != '')
                maker.channel.description = feed.summary
            else
                maker.channel.description = ' ' # the rss won't get emitted if description is empty
            end

            if (rubyFeed&.respond_to?(:channel) && rubyFeed&.channel&.image)
                maker.image.url = rubyFeed.channel.image.url
                maker.image.title =  rubyFeed.channel.image.title
                maker.image.width = rubyFeed.channel.image.width if rubyFeed.channel.image.width
                maker.image.height = rubyFeed.channel.image.height if rubyFeed.channel.image.height
                maker.image.description = rubyFeed.channel.image.description
            end

            feed.items.each do |item|
                maker.items.new_item do |newItem|
                    newItem = transferData(newItem, item)
                end
            end
        end
        return rss
    end

    # detect feeds for important sites that don't advertise them, youtube so far
    def detectHiddenFeeds(url)
        if (url.include?('www.youtube.com'))
            p  url.scan(/https:\/\/www.youtube.com\/[^\/]+$/)
            case
            when url.include?('www.youtube.com/channel')
                feedid = url.scan(/channel\/[^\/]+/).first.gsub('channel/', '')
                url = 'https://www.youtube.com/feeds/videos.xml?channel_id=' + feedid
            when url.include?('www.youtube.com/user')
                feedid = url.scan(/user\/[^\/]+/).first.gsub('user/', '')
                url = 'https://www.youtube.com/feeds/videos.xml?user=' + feedid
            when (url.include?('www.youtube.com/playlist?list') || (url.include?('www.youtube.com/watch?') && url.include?('list=')))
                feedid = url.scan(/list=[^\/]+/).first.gsub('list=', '')
                url = 'https://www.youtube.com/feeds/videos.xml?playlist_id=' + feedid
            end
        end
        return url
    end

end