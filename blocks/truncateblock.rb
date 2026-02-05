require 'rss'
require 'feedparser'

class Truncateblock < Block
    def process(inputs)
        feed = inputs[0]
        limit = options[:userinput].to_i if self.options[:userinput]
        limit = self.options[:userinputs][0].to_i if self.options[:userinputs]
        limit = 1 if limit < 1

        rss = RSS::Maker.make("rss2.0") do |maker|
            transferChannel(maker, feed)

            feed.items.take(limit).each do |item|
                maker.items.new_item do |newItem|
                    newItem = transferData(newItem, item)
                end
            end
        end

        return rss
       
    end

end