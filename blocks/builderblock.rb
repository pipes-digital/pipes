class Builderblock < Block
    def process(inputs)
        if self.options[:userinputs]
            title = self.options[:userinputs][0]
        end
        # title, content, description, date
        titleFeed = contentFeed = descriptionFeed = dateFeed = linkFeed = nil
        titleFeed = convertToFeeds(inputs[0]) if inputs[0]
        begin
            contentFeed = convertToFeeds(inputs[1])
        rescue NoMethodError => nme
            return '<rss version="2.0"><channel><title>Could not build feed</title><link></link><description>Could not create a feed, did you connect something to the content input?</description></channel></rss>'
        end
        dateFeed = convertToFeeds(inputs[2]) if inputs[2]
        linkFeed = convertToFeeds(inputs[3]) if inputs[3]

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = Time.now
            if title && ! title.nil? && ! title.empty?
                maker.channel.title = title
            else
                maker.channel.title = self.pipe.title || 'Feed created by Pipes'
            end
            maker.channel.link = 'https://www.pipes.digital/feed/' + self.pipe.encodedId
            maker.channel.description = ' ' # the rss won't get emitted if description is empty

            for i in 0...contentFeed.items.length
                maker.items.new_item do |newItem|
                    if titleFeed && titleFeed.items[i]
                        newItem.title = titleFeed.items[i].content
                    else
                        newItem.title = 'untitled'
                    end
                    if dateFeed && dateFeed.items[i]
                        newItem.updated = dateFeed.items[i].content
                    else
                        newItem.updated = Time.now
                    end
                    if linkFeed && linkFeed.items[i]
                        newItem.link = linkFeed.items[i].content
                    end
                    newItem.content_encoded = contentFeed.items[i].content
                    if contentFeed.items[i].guid
                        newItem.guid.content = contentFeed.items[i].guid
                    else
                        begin
                            newItem.guid.content = Digest::MD5.hexdigest(contentFeed.items[i].content)
                        rescue TypeError => te
                            newItem.guid.content = Digest::MD5.hexdigest(contentFeed.items[i].title)
                        end
                    end
                    newItem.guid.isPermaLink = newItem.guid.content.include?('http')
                end
            end
        end

        return rss.to_s
    end

    def convertToFeeds(input)
        begin
            return FeedParser::Parser.parse(input)
        rescue
            rss = RSS::Maker.make("rss2.0") do |maker|
                maker.channel.updated = Time.now
                maker.channel.title = 'Feed created by Pipes'
                maker.channel.link = ' '
                maker.channel.description = ' ' # the rss won't get emitted if description is empty

                input.lines.each do |line|
                    maker.items.new_item do |newItem|
                        newItem.title = 'untitled'
                        newItem.updated = Time.now
                        newItem.content_encoded = line
                        newItem.guid.content = Digest::MD5.hexdigest(line)
                    end
                end
            end
            return FeedParser::Parser.parse(rss.to_s)
        end
    end

end