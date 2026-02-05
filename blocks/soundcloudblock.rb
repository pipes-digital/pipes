class SoundcloudBlock < Block

    def process(inputs)
        keyword = self.options[:userinputs][0]
        
        return inputs[0] if keyword.empty?

        data = 'all'  # data in feed, all by default
        data =  self.options[:userinputs][1] if self.options[:userinputs][1]
        queryPart = '&t=' + data
        
        boxfeed = getFromBridge('Soundcloud', keyword, queryPart)
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

    def getFromBridge(bridge, context, queryPart)
        query = ENV.fetch('PIPES_RSSBRIDGE') + '?action=display&bridge=' + bridge + '&u=' + context + queryPart + '&format=Mrss'
        downloader = Downloader.new
        downloader.get(query)
    end

end