require 'nokogiri'
require 'rss'
require 'feedparser'

class Insertblock < Block
    def process(inputs)
        insertElements = inputs[0]
        feed = inputs[1]
        target = self.options[:userinputs][0] if self.options[:userinputs]
        replacementMode = self.options[:userinputs][1] if self.options[:userinputs]

        if ! target || target.empty?
            return self.errorFeed('No target', 'Please provide an xpath telling this block where to insert the element.')
        end

        if ! feed
            return self.errorFeed('No feed to insert into', 'Please connect a feed to the second input.')
        end

        feed = Nokogiri::XML(feed.to_s)
        feed.xpath(target).each do |node|
            if replacementMode
                node.content = insertElements.items.first.content
            else
                node << insertElements.items.first.content
            end
        end
        
        return RSS::Parser.parse(feed.to_s)
       
    end

end