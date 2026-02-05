class Foreachblock < Block
    def process(inputs)
        mode = "empty"
        if self.options[:userinputs]
            mode = self.options[:userinputs][0]
        end
        if mode == "empty"
            return self.errorFeed('No action to do', 'Got the block a download, feed or tweet block?')
        end
        feed = inputs[0]

        rss = RSS::Maker.make("rss2.0") do |maker|
            transferChannel(maker, feed)

            case mode
            when "download"
                # we download as much as possible and put each download result into one item of a feed
                feed.items.each do |item|
                    block = Downloadblock.new
                    block.options[:userinputs] = [item&.content]
                    maker.items.new_item do |newItem|
                        transferData(newItem, item)
                        newItem.content_encoded = '<![CDATA[' + block.run + ']]'
                        newItem.link = item&.content
                    end
                end
                
            when "feed"
                # we fetch all the feeds and append their items together
                feed.items.each do |item|
                    block = Feedblock.new
                    block.options[:userinputs] = [item&.content]
                    fetchedFeed = block.run
                    fetchedFeed.items.each do |fetchedItem|
                        maker.items.new_item do |newItem|
                            newItem = transferData(newItem, fetchedItem)
                        end
                    end
                end
            when "tweets"
                return self.errorFeed('Twitter Block deactivated', 'With the API changes the twitter block had to be deactivated.')
            end
        end


        return rss
    end

end