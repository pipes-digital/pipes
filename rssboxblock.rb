class RssboxBlock < Block

    def process(inputs)
        keyword = self.options[:userinputs][0]
        # title, content, description, date

        return inputs[0] if keyword.empty?

        boxfeed = getFromBox(rssboxEndpoint + '?q=' + keyword)
        feed = FeedParser::Parser.parse(boxfeed)
       
        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = feed.updated
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

            feed.items.each do |item|
                maker.items.new_item do |newItem|
                    newItem = transferData(newItem, item)
                end
            end
        end

        return rss
    end

    def getFromBox(urlPart)
        rssboxQuery = ENV.fetch('PIPES_RSSBOX') + urlPart
        downloader = Downloader.new
        downloader.get(rssboxQuery)
    end

end
