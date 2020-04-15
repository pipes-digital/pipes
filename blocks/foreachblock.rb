class Foreachblock < Block
    def process(inputs)
        mode = "empty"
        if self.options[:userinputs]
            mode = self.options[:userinputs][0]
        end
        if mode == "empty"
            return '<rss version="2.0"><channel><title>No action to do</title><link></link><description>Got the block a download, feed or tweet block?</description></channel></rss>'
        end
        begin
            feed = FeedParser::Parser.parse(inputs[0])
        rescue NoMethodError => nme
            return '<rss version="2.0"><channel><title>Feed could not be parsed</title><link></link><description>Is the feed given to this block empty?</description></channel></rss>'
        end

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = feed.updated&.to_s
            maker.channel.title = feed.title    # the title should be overwritten later depending on the action we do
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

            case mode
            when "download"
                # we download as much as possible and put each download result into one item of a feed
                feed.items.each do |item|
                    block = Downloadblock.new
                    block.options[:userinputs] = [item&.content]
                    maker.items.new_item do |newItem|
                        newItem.title = item.title
                        if item.updated
                            newItem.updated = item.updated.to_s
                        end
                        newItem.pubDate = item.published.to_s if item.published
                        if (item.url && item.url != '')
                            newItem.link = item.url
                        else
                            newItem.link = '' # the rss won't get emitted if link is empty
                        end
                        newItem.content_encoded = '<![CDATA[' + block.run + ']]'
                        newItem.guid.content = item.guid
                        newItem.guid.isPermaLink = item.guid.include?('http')
                        newItem.description = item.summary if item.summary && ! item.summary.empty?
                        newItem.author = item.author if item.author
                    end
                end
                
            when "feed"
                # we fetch all the feeds and append their items together
                feed.items.each do |item|
                    block = Feedblock.new
                    block.options[:userinputs] = [item&.content]
                    fetchedFeed = block.run
                    fetchedFeed = FeedParser::Parser.parse(fetchedFeed)
                    fetchedFeed.items.each do |fetchedItem|
                        maker.items.new_item do |newItem|
                            newItem.title = fetchedItem.title
                            if item.updated
                                newItem.updated = fetchedItem.updated.to_s
                            end
                            newItem.pubDate = fetchedItem.published.to_s if fetchedItem.published
                            if (fetchedItem.url && fetchedItem.url != '')
                                newItem.link = fetchedItem.url
                            else
                                newItem.link = '' # the rss won't get emitted if link is empty
                            end
                            newItem.content_encoded = fetchedItem.content
                            newItem.guid.content = fetchedItem.guid
                            newItem.guid.isPermaLink = fetchedItem.guid.include?('http')
                            newItem.description = fetchedItem.summary if fetchedItem.summary && ! fetchedItem.summary.empty?
                            newItem.author = fetchedItem.author if fetchedItem.author
                            fetchedItem.categories.each do |category|
                                target = newItem.categories.new_category
                                target.content = category.name
                                target.domain = category.scheme
                            end
                        end
                    end
                end
            when "tweets"
                # we fetch all the tweets and append the items together
                 feed.items.each do |item|
                    block = Twitterblock.new
                    block.options[:userinputs] = [item&.content]
                    fetchedFeed = block.run
                    fetchedFeed = FeedParser::Parser.parse(fetchedFeed)
                    fetchedFeed.items.each do |fetchedItem|
                        maker.items.new_item do |newItem|
                            newItem.title = fetchedItem.title
                            if item.updated
                                newItem.updated = fetchedItem.updated.to_s
                            end
                            newItem.pubDate = fetchedItem.published.to_s if fetchedItem.published
                            if (fetchedItem.url && fetchedItem.url != '')
                                newItem.link = fetchedItem.url
                            else
                                newItem.link = '' # the rss won't get emitted if link is empty
                            end
                            newItem.content_encoded = fetchedItem.content
                            newItem.guid.content = fetchedItem.guid
                            newItem.guid.isPermaLink = fetchedItem.guid.include?('http')
                            newItem.description = fetchedItem.summary if fetchedItem.summary && ! fetchedItem.summary.empty?
                            newItem.author = fetchedItem.author if fetchedItem.author
                            fetchedItem.categories.each do |category|
                                target = newItem.categories.new_category
                                target.content = category.name
                                target.domain = category.scheme
                            end
                        end
                    end
                end
            end
        end


        return rss.to_s
    end

end