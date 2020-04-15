require 'rss'
require 'feedparser'

class Sortblock < Block
    def process(inputs)
        rss = RSS::Maker.make("rss2.0") do |maker|
            feed = FeedParser::Parser.parse(inputs[0])
            sortitem = self.options[:userinputs][0] if self.options[:userinputs]
            sortorder = self.options[:userinputs][1] if self.options[:userinputs]
            
            maker.channel.title = feed.title

            if feed.updated
                maker.channel.updated = feed.updated.to_s
            else
                maker.channel.updated = Time.at(0).to_datetime.to_s
            end

            if (feed.summary && feed.summary != '')
                maker.channel.description = feed.summary
            else
                maker.channel.description = ' ' # the rss won't get emitted if description is empty
            end
            
            if (feed.url && feed.url != '')
                maker.channel.link = feed.url
            else
                if (feed.feed_url && feed.feed_url != '')
                    maker.channel.link = feed.feed_url
                else
                    maker.channel.link = ' ' # the rss won't get emitted if link is empty
                end
            end

            items = feed.items.sort_by do |x|
                case sortitem
                when 'updated' then x.updated
                when 'published' then x.published
                when 'content' then x.content
                when 'summary' then x.summary
                when 'url' then x.url
                when 'title' then x.title
                when 'guid' then x.guid
                end
            end 
            items.reverse! if sortorder == 'desc' 
            items.each do |item|
                maker.items.new_item do |newItem|
                    newItem.title = item.title
                    if item.updated
                        newItem.updated = item.updated.to_s
                    end
                    newItem.pubDate = item.published.to_s if item.published
                    if (item.url && item.url != '')
                        newItem.link = item.url
                    else
                        newItem.link = ''
                    end
                    newItem.content_encoded = item.content
                    newItem.guid.content = item.guid
                    newItem.description = item.summary if item.summary && ! item.summary.empty?
                    newItem.guid.isPermaLink = item.guid.include?('http')
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

        if rss.items.size == 0
            return '<rss version="2.0"><channel><title>Nothing to sort</title><link></link><description>The input feed contained no items.</description></channel></rss>'
        end
        
        return rss.to_s
    end

end