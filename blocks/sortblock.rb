require 'rss'
require 'feedparser'

class Sortblock < Block
    def process(inputs)
        feed = inputs[0]
        sortitem = self.options[:userinputs][0] if self.options[:userinputs]
        sortorder = self.options[:userinputs][1] if self.options[:userinputs]

        if feed.items.size == 0
            return self.errorFeed('Nothing to sort', 'The input feed contained no items.')
        end
        
        rss = RSS::Maker.make("rss2.0") do |maker|
            self.transferChannel(maker, feed)

            items = feed.items.sort_by do |x|
                case sortitem
                when 'updated' then x.updated
                when 'published' then x.pubDate
                when 'content' then x.content
                when 'summary' then x.summary
                when 'url' then x.url
                when 'title' then x.title
                when 'guid' then x.guid.content
                end
            end 
            items.reverse! if sortorder == 'desc' 
            items.each do |item|
                maker.items.new_item do |newItem|
                    newItem = transferData(newItem, item)
                end
            end
        end
        
        return rss
    end

end