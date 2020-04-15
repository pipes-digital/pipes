require 'rss'
require 'feedparser'
require 'to_regexp'

class Mergeblock < Block
    def process(inputs)
        begin
            feed1 = FeedParser::Parser.parse(inputs[0])
        rescue NoMethodError
        end
        begin
            feed2 = FeedParser::Parser.parse(inputs[1])
        rescue NoMethodError
        end
        scheme = self.options[:userinputs][0] if self.options[:userinputs]

        return inputs[0] if (! inputs[1] && inputs[0])
        return inputs[1] if (! inputs[0] && inputs[1])

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = feed1.updated if feed1.updated
            maker.channel.updated = feed2.updated if feed2.updated
            if feed1.updated && feed2.updated
                if feed1.updated > feed2.updated
                    maker.channel.updated = feed1.updated
                else
                    maker.channel.updated = feed2.updated
                end
            end
            maker.channel.title = feed1.title + " & " + feed2.title
            if (feed1.url && feed1.url != '')
                maker.channel.link = feed1.url
            else
                if (feed1.feed_url && feed1.feed_url != '')
                    maker.channel.link = feed1.feed_url
                else
                    maker.channel.link = ' ' # the rss won't get emitted if link is empty
                end
            end
            if (feed1.summary && feed1.summary != '')
                maker.channel.description = feed1.summary
            else
                maker.channel.description = ' ' # the rss won't get emitted if description is empty
            end

            feed1.items.each_with_index do |item, index|
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
                    newItem.content_encoded = merge(scheme, item.content.to_s, feed2.items[index].content.to_s)
                    newItem.description = merge(scheme, item.summary.to_s, feed2.items[index].summary.to_s)
                    newItem.author = item.author if item.author
                    if item.author
                        newItem.author += feed2.items[index].author if feed2.items[index].author 
                    else
                        newItem.author = feed2.items[index].author if feed2.items[index].author
                    end
                    if item.attachments?
                        newItem.enclosure.url = item.attachment.url
                        newItem.enclosure.length = item.attachment.length
                        newItem.enclosure.type = item.attachment.type
                    else
                        if feed2.items[index].attachments?
                            newItem.enclosure.url = feed2.items[index].attachment.url
                            newItem.enclosure.length = feed2.items[index].attachment.length
                            newItem.enclosure.type = feed2.items[index].attachment.type
                        end
                    end
                    newItem.guid.content = Digest::MD5.hexdigest(newItem.description.to_s + newItem.content_encoded.to_s)
                    item.categories.each do |category|
                        target = newItem.categories.new_category
                        target.content = category.name
                        target.domain = category.scheme
                    end
                    feed2.items[index].categories.each do |category|
                        target = newItem.categories.new_category
                        target.content = category.name
                        target.domain = category.scheme
                    end
                end
            end
        end

        return rss.to_s
    end

    # merge merges the two inputs into one, following scheme
    # if scheme is empty, it will just append input2 to input1
    # if scheme is just a regular string, it will palce itself between input1 and input2
    # if scheme contains the strings \1 and \2, it will replace them with input1/input2
    def merge(scheme, input1, input2)
        if (((! input1) || input1.empty?) && ((! input2) || input2.empty?))
            return ""
        end
        if ! scheme || scheme.empty?
            return input1 + input2
        end
        if ! (scheme.include?('\1') && scheme.include?('\2'))
            return input1 + scheme + input2
        end
        return scheme.gsub(/\\1|\\2/, {'\1' => input1, '\2' => input2})
    end

end