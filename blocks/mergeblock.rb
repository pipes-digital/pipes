require 'rss'
require 'feedparser'
require 'to_regexp'

class Mergeblock < Block
    def process(inputs)
        feed1 = inputs[0]
        feed2 = inputs[1]

        scheme = self.options[:userinputs][0] if self.options[:userinputs]

        return inputs[0] if (! inputs[1] && inputs[0])
        return inputs[1] if (! inputs[0] && inputs[1])

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = feed1.channel.pubDate if feed1.channel.pubDate
            maker.channel.updated = feed2.channel.pubDate if feed2.channel.pubDate
            if feed1.channel.pubDate && feed2.channel.pubDate
                if feed1.channel.pubDate > feed2.channel.pubDate
                    maker.channel.updated = feed1.channel.pubDate
                else
                    maker.channel.updated = feed2.channel.pubDate
                end
            end
            maker.channel.title = feed1.channel.title + " & " + feed2.channel.title
            if (feed1.channel.link && feed1.channel.link != '')
                maker.channel.link = feed1.channel.link
            else
                if (feed2.channel.link && feed2.channel.link != '')
                    maker.channel.link = feed2.channel.link
                else
                    maker.channel.link = ' ' # the rss won't get emitted if link is empty
                end
            end
            if (feed1.channel.description && feed1.channel.description != '')
                maker.channel.description = feed1.channel.description
            else
                if (feed2.channel.description && feed2.channel.description != '')
                    maker.channel.description = feed2.channel.description
                else
                    maker.channel.description = ' ' # the rss won't get emitted if description is empty
                end
            end

            feed1.items.each_with_index do |item, index|
                maker.items.new_item do |newItem|
                    newItem.title = item.title
                    newItem.updated = item.updated if item.updated
                    if (item.url && item.url != '')
                        newItem.link = item.url
                    else
                        newItem.link = ' ' # the rss won't get emitted if link is empty
                    end
                    newItem.content_encoded = merge(scheme, item.content.to_s, feed2.items[index].content.to_s)
                    newItem.description = merge(scheme, item.summary.to_s, feed2.items[index].summary.to_s)
                    newItem.author = item.author if item.author
                    if item.author
                        newItem.author = item.author.to_s + feed2.items[index].author.to_s if feed2.items[index].author 
                    else
                        newItem.author = feed2.items[index].author if feed2.items[index].author
                    end
                    if item.enclosure
                        newItem.enclosure.url = item.enclosure.url
                        newItem.enclosure.length = item.enclosure.length
                        newItem.enclosure.type = item.enclosure.type
                        if (newItem.description.nil? || newItem.description.empty?) && item.enclosure.description
                            newItem.description = item.enclosure.description.gsub(/\n/,"<br />\n")
                        end
                    else
                        if feed2.items[index].enclosure
                            newItem.enclosure.url = feed2.items[index].enclosure.url
                            newItem.enclosure.length = feed2.items[index].enclosure.length
                            newItem.enclosure.type = feed2.items[index].enclosure.type
                            if (newItem.description.nil? || newItem.description.empty?) && feed2.items[index].enclosure.description
                                newItem.description = feed2.items[index].enclosure.description.gsub(/\n/,"<br />\n")
                            end
                        end
                    end
                    newItem.guid.content = Digest::MD5.hexdigest(newItem.description.to_s + newItem.content_encoded.to_s)
                    item.categories.each do |category|
                        target = newItem.categories.new_category
                        target.content = category.content
                        target.domain = category.domain
                    end
                    feed2.items[index].categories.each do |category|
                        target = newItem.categories.new_category
                        target.content = category.content
                        target.domain = category.domain
                    end
                end
            end
        end

        return rss
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