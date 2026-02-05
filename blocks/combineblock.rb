require 'rss'
require 'feedparser'

class Combineblock < Block

    def process(inputs)
        rss = RSS::Maker.make("rss2.0") do |maker|
            items = []
            
            inputs.each do |input|
                next if input.nil?
                feed = input
                
                if maker.channel.title
                    maker.channel.title += " & "  + feed.channel.title
                else
                    maker.channel.title = feed.channel.title
                end


                if maker.channel.updated
                    maker.channel.updated = feed.channel.pubDate if feed.channel.pubDate && feed.channel.pubDate > maker.channel.updated
                else
                    if feed.channel.pubDate
                        maker.channel.updated = feed.channel.pubDate
                    else
                        maker.channel.updated = Time.at(0).to_datetime.to_s
                    end
                end

                if maker.channel.description && maker.channel.description != ""
                    maker.channel.description += " & "  + feed.channel.description.to_s
                else
                    if (feed.channel.description && feed.channel.description != '')
                        maker.channel.description = feed.channel.description
                    else
                        maker.channel.description = ' ' # the rss won't get emitted if description is empty
                    end
                end
                
                maker.channel.link = 'https://www.pipes.digital/feed/' + self.pipe.encodedId

                items.concat(feed.items)
            end
            
            items.each do |item|
                maker.items.new_item do |newItem|
                    newItem = transferData(newItem, item)
                end
            end
        end

        if rss.items.size == 0
            self.errorFeed('Nothing to combine', 'Nothing to combine. Most likely reason is that the input feeds contained no items.')
        end
        return rss
    end

end