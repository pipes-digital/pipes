require 'rss'
require 'feedparser'

class Uniqueblock < Block
    def process(inputs)
        feed = inputs[0]

        rss = RSS::Maker.make("rss2.0") do |maker|
            self.transferChannel(maker, feed)

            feed.items.uniq{|x| x.guid&.content }.each do |item|
                maker.items.new_item do |newItem|
                    newItem = transferData(newItem, item)
                end
            end
        end

        return rss
       
    end

end