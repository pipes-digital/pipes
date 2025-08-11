require 'nokogiri'
require 'jsonpath'
require 'digest/md5'

class ImagesBlock < Block

    def process(inputs)
        if self.options[:userinputs]
            selector = self.options[:userinputs][0]
        end

        if Nokogiri::XML(inputs[0]) { |config| config.nonet.noent }.root.name == 'html'
            mode = 'html'
            contents = [inputs[0]]
        else
            mode = 'xml'
            contents = Nokogiri::XML(inputs[0]) { |config| config.nonet.noent }.xpath('//item/content:encoded').map{|x| x.content }
        end

        case mode
            when 'html'
                selector = 'img'
                attribute = 'OuterXml'
            when 'xml'
                selector = 'img'
                attribute = 'OuterXml'
        end
        
        items = []
        contents.each do |content|
            doc = Nokogiri::HTML(content)
            items.concat(doc.search(selector))
        end

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = Time.now
            maker.channel.title = 'Extracted Image'
            maker.channel.link = ' '
            maker.channel.description = ' ' # the rss won't get emitted if description is empty

            items.each do |item|
                maker.items.new_item do |newItem|
                    newItem.title = 'Extracted Image'
                    newItem.updated = Time.now
                    if mode == 'json'
                        value = item.to_s
                    else
                        if (selector =~ /^concat\(/)
                            value = item
                        else
                            if (! attribute || attribute == '' || attribute == 'content') 
                                value = item.inner_html
                            else
                                if attribute == 'OuterXml'
                                    value = item
                                else
                                    value = item[attribute]
                                end
                            end
                        end
                    end
                    newItem.content_encoded = value
                    newItem.guid.content = Digest::MD5.hexdigest(value)
                    newItem.guid.isPermaLink = false
                end
            end
        end

        return rss.to_s
    end

end