require 'rss'
require 'feedparser'
require 'to_regexp'

class ShortenBlock < Block
    def process(inputs)
        feed = inputs[0]
        
        length = self.options[:userinputs][0] if self.options[:userinputs]
        field = self.options[:userinputs][1] if self.options[:userinputs]
        length = 200 if length.empty?
        length = length.to_i

        rss = RSS::Maker.make("rss2.0") do |maker|
            self.transferChannel(maker, feed)

            feed.items.each do |item|
                case field
                    when 'title' then item.title = Strings.truncate(item.title, length)
                    when 'summary' then item.description = Strings.truncate(item.summary, length)
                    when 'content' then item.content_encoded = Strings.truncate(item.content, length)
                end
                
                maker.items.new_item do |newItem|
                    newItem = transferData(newItem, item)
                end
            end
        end

        return rss
       
    end

end