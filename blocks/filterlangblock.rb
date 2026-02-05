require 'rss'
require 'feedparser'
require 'scylla'

class FilterlangBlock < Block
    def process(inputs)
        feed = inputs[0]
        
        field = 'all'
        language = 'english'
        language = self.options[:userinputs][0] if self.options[:userinputs]
        blockMode = self.options[:userinputs][1] if self.options[:userinputs]
        field = self.options[:userinputs][2] if self.options[:userinputs]

        rss = RSS::Maker.make("rss2.0") do |maker|
            self.transferChannel(maker, feed)

            feed.items.each do |item|
                case field
                    when 'all' then text = item.title.to_s + item.summary.to_s + item.description.to_s + item.content.to_s
                    when 'title' then text = item.title .to_s
                    when 'summary' then text = item.summary .to_s
                    when 'description' then text = item.description.to_s
                    when 'content' then text = item.content.to_s
                end
                accept = text.language == language
                accept = ! accept if blockMode
                
                if accept
                    maker.items.new_item do |newItem|
                        newItem = transferData(newItem, item)
                    end
                end
            end
        end

        return rss
       
    end

end