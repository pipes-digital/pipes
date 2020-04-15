require 'rss'
require 'feedparser'

class Combineblock < Block

    def process(inputs)
        rss = RSS::Maker.make("rss2.0") do |maker|
            items = []
            
            inputs.each do |input|
                next if input.nil?
                begin
                    feed = FeedParser::Parser.parse(input)
                rescue NameError => nme
                    # a name error can happen if the feed is nil
                    next
                end
                
                if maker.channel.title
                    maker.channel.title += " & "  + feed.title
                else
                    maker.channel.title = feed.title
                end


                if maker.channel.updated
                    maker.channel.updated = feed.updated.to_s if feed.updated && feed.updated > maker.channel.updated
                else
                    if feed.updated
                        maker.channel.updated = feed.updated.to_s
                    else
                        maker.channel.updated = Time.at(0).to_datetime.to_s
                    end
                end

                if maker.channel.description && maker.channel.description != ""
                    maker.channel.description += " & "  + feed.summary.to_s
                else
                    if (feed.summary && feed.summary != '')
                        maker.channel.description = feed.summary
                    else
                        maker.channel.description = ' ' # the rss won't get emitted if description is empty
                    end
                end
                
                items.concat(feed.items)
            end
            
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

        if rss.items.size == 0
            return '<rss version="2.0"><channel><title>Nothing to combine</title><link></link><description>Nothing to combine. Most likely reason is that the input feeds contained no items.</description></channel></rss>'
        end
        return rss.to_s
    end

end