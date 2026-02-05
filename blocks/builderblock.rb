class Builderblock < Block
    def process(inputs)
        if self.options[:userinputs]
            title = self.options[:userinputs][0]
            recalculateGUID = self.options[:userinputs][1]
        end
        # title, content, description, date
        titleFeed = contentFeed = descriptionFeed = dateFeed = linkFeed = nil
        titleFeed = convertToFeeds(inputs[0]) if inputs[0]
        begin
            contentFeed = convertToFeeds(inputs[1])
        rescue NoMethodError => nme
            return self.errorFeed('Could not build feed', 'Could not create a feed, did you connect something to the content input?')
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
                    if linkFeed && linkFeed.items[i]
                        newItem.link = linkFeed.items[i].content
                    end
                    newItem.content_encoded = contentFeed.items[i].content
                    if contentFeed.items[i].guid && ! recalculateGUID
                        newItem.guid.content = contentFeed.items[i].guid.content
                    else
                        newItem.guid.content = Digest::MD5.hexdigest(contentFeed.items[i].content.to_s + contentFeed.items[i].title.to_s)
                    end
                    newItem.guid.isPermaLink = newItem.guid.content.include?('http') || false

                    if dateFeed && dateFeed.items[i]
                        newItem.updated = dateFeed.items[i].content
                    else
                        # because we want the date to stay stable we create it only once for each item
                        itemDate = Database.instance.getset(newItem.guid.content + '_' + self.id + '_' + self.pipe.encodedId, Time.now.to_s)
                        newItem.updated = itemDate
                    end
                end
            end
        end

        return rss
    end

    def convertToFeeds(input)
        if input.class == RSS::Rss
            return input
        else
            # we probably got a String, directly from a download block. To enable manipulation
            # of its data we transform it to RSS line by line
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
            return rss
        end
    end

end