require 'nokogiri'
require 'jsonpath'
require 'digest/md5'

class Extractblock < Block

    def process(inputs)
        if self.options[:userinputs]
            selector = self.options[:userinputs][0]
            attribute = self.options[:userinputs][1]
            extract_content = self.options[:userinputs][2]
        end

        return self.errorFeed('Selector missing', 'The extraction block is missing a selector') if selector.empty?

        case selector
            when /\/.*/ then mode = 'xml'
            when /\$.*/ then mode = 'json'
            else mode = 'html'
        end

        if extract_content === true
            contents = Nokogiri::XML(inputs[0]).xpath('//item/content:encoded').map{|x| x.content }
        else
            contents = [inputs[0]]
        end

        items = []
        contents.each do |content|
            case mode
                when 'html'
                    if extract_content
                        # For the HTML parser to work we need to remove the CDATA wrapper, if it exists
                        content = content.strip.gsub(/\A<!\[CDATA\[/, '')
                        content = content.strip.gsub(/\]\]\z/, '')
                    end
                    doc = Nokogiri::HTML(content)
                when 'xml' then doc = Nokogiri::XML(content.to_s)
                when 'json' then doc = JSON.parse(content.to_s)
            end
            
            if mode != 'json'
                if (selector =~ /^concat\(/)
                    # we call this as xpath to enable the concat xpath expression, see https://github.com/pipes-digital/pipes/issues/35
                    # we could just extend LOOKS_LIKE_XPATH, but concat() returns a string, not an array
                    items.concat([doc.xpath(selector)])
                else
                    items.concat(doc.search(selector))
                end
            else
                items.concat(JsonPath.on(doc, selector))
            end
        end

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = Time.now
            maker.channel.title = 'Extracted Content'
            maker.channel.link = ''
            maker.channel.description = ' ' # the rss won't get emitted if description is empty

            items.each do |item|
                maker.items.new_item do |newItem|
                    newItem.title = 'Extracted Content'
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
                    newItem.guid.content = Digest::MD5.hexdigest(value.to_s)
                    newItem.guid.isPermaLink = false
                    newItem.link = ''
                end
            end
        end

        return rss
    end

end