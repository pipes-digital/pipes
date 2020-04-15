require 'rss'
require 'feedparser'

class Uniqueblock < Block
    def process(inputs)
        feed = FeedParser::Parser.parse(inputs[0])
        

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = feed.updated
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

            feed.items.uniq{|x| x.guid }.each do |item|
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
                    newItem.description = item.summary if item.summary && ! item.summary.empty?
                    newItem.guid.content = item.guid
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

        return rss.to_s
       
    end

end