require 'rss'
require 'feedparser'
require 'to_regexp'

class Filterblock < Block
    def process(inputs)
        begin
            feed = FeedParser::Parser.parse(inputs[0])
        rescue NoMethodError => nme
            return '<rss version="2.0"><channel><title>Feed could not be parsed</title><link></link><description>Is the feed given to this block empty?</description></channel></rss>'
        end
        filter = self.options[:userinput] if self.options[:userinput]
        filter = self.options[:userinputs][0] if self.options[:userinputs]
        blockMode = self.options[:userinputs][1] if self.options[:userinputs]
        field = self.options[:userinputs][2] if self.options[:userinputs]

        return inputs[0] if filter.empty?

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = feed.updated&.to_s
            maker.channel.title = feed.title
            if (feed.url && feed.url != '')
                maker.channel.link = feed.url
            else
                if (feed.feed_url && feed.feed_url != '')
                    maker.channel.link = feed.feed_url
                else
                    maker.channel.link = ' ' # the rss won't get emitted if link is empty
                end
            end
            if (feed.summary && feed.summary != '')
                maker.channel.description = feed.summary
            else
                maker.channel.description = ' ' # the rss won't get emitted if description is empty
            end

            feed.items.each do |item|
                begin
                    regexp = filter.to_regexp(detect: true)
                rescue RegexpError => re
                    return '<rss version="2.0"><channel><title>Invalid regexpression</title><link></link><description>' + re.message + '</description></channel></rss>'
                end
                case field
                    when 'all' then accept = ! (item.content&.match(regexp).nil? && item.title&.match(regexp).nil? && item.summary&.match(regexp).nil? && item.url&.match(regexp).nil? && (! item.categories.any?{|x| ! (x.name&.match(regexp).nil? && x.scheme&.match(regexp).nil?) })) 
                    when 'title' then accept = ! (item.title&.match(regexp).nil?)
                    when 'summary' then accept = ! (item.summary&.match(regexp).nil?)
                    when 'content' then accept = ! (item.content&.match(regexp).nil?)
                    when 'link' then accept = ! (item.url&.match(regexp).nil?)
                    when 'author' then accept = ! (item.author&.name&.match(regexp).nil?)
                    when 'category' then accept = item.categories.any?{|x| ! (x.name&.match(regexp).nil? && x.scheme&.match(regexp).nil?) }
                    else accept = ! (item.content&.match(regexp).nil? && item.title&.match(regexp).nil? && item.summary&.match(regexp).nil? && item.url&.match(regexp).nil?)
                end
                accept = ! accept if blockMode
                
                if accept
                    maker.items.new_item do |newItem|
                        newItem.title = item.title
                        if item.updated
                            newItem.updated = item.updated.to_s
                        end
                        newItem.pubDate = item.published.to_s if item.published
                        if (item.url && item.url != '')
                            newItem.link = item.url
                        else
                            newItem.link = '' # the rss won't get emitted if description is empty
                        end
                        newItem.content_encoded = item.content
                        newItem.guid.content = item.guid
                        newItem.guid.isPermaLink = item.guid.include?('http')
                        newItem.description = item.summary if item.summary && ! item.summary.empty?
                        newItem.author = item.author if item.author
                        if item.attachments?
                            newItem.enclosure.url = item.attachment.url
                            newItem.enclosure.length = item.attachment.length
                            newItem.enclosure.type = item.attachment.type
                        end
                        item.categories.each do |category|
                            target = newItem.categories.new_category
                            target.content = category.name
                            target.domain = category.scheme
                        end
                    end
                end
            end
        end

        return rss.to_s
       
    end

end