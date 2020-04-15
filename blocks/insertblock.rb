require 'nokogiri'   
require 'feedparser'

class Insertblock < Block
    def process(inputs)
        begin
            insertElements = FeedParser::Parser.parse(inputs[0])
        rescue NoMethodError => nme
            return '<rss version="2.0"><channel><title>Feed with the element to insert could not be parsed</title><link></link><description>Is the feed given to this block empty?</description></channel></rss>'
        end
        feed = inputs[1]
        target = self.options[:userinputs][0] if self.options[:userinputs]

        if ! target || target.empty?
            return '<rss version="2.0"><channel><title>No target</title><link></link><description>Please provide an xpath telling this block where to insert the element.</description></channel></rss>'
        end

        if ! feed || feed.empty?
            return '<rss version="2.0"><channel><title>No feed to insert into</title><link></link><description>Please connect a feed to the second input.</description></channel></rss>'
        end

        feed = Nokogiri::XML(feed)
        feed.xpath(target).each do |node|
            node << insertElements.items.first.content
        end
        
        return feed.to_s
       
    end

end