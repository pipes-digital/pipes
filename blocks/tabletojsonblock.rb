require 'nokogiri'   
require 'feedparser'

class TabletojsonBlock < Block
    def process(inputs)
        if self.options[:userinputs]
            selector = self.options[:userinputs][0]
        end

        if Nokogiri::XML(inputs[0]).root.name == 'html'
            mode = 'html'
            contents = [inputs[0]]
        else
            mode = 'xml'
            contents = Nokogiri::XML(inputs[0]).xpath('//item/content:encoded').map{|x| x.content }
        end
        
        items = []
        result = {}
        contents.each do |content|
            doc = Nokogiri::HTML(content)
            doc.css('table').each do |table|
                table.css('tr').each do |tr|
                    tds = tr.css('td')
                    if tds.size > 1
                        result[tds[0].content] = []
                        (1..(tds.size - 1)).each do |i|
                            result[tds[0].content].push(tds[i].content)
                        end
                    end
                end
                items.push(JSON.generate(result))
            end
        end

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = Time.now
            maker.channel.title = 'Extracted Tables'
            maker.channel.link = ' '
            maker.channel.description = ' ' # the rss won't get emitted if description is empty

            items.each do |item|
                maker.items.new_item do |newItem|
                    newItem.title = 'Table as json'
                    newItem.updated = Time.now
                    newItem.content_encoded = item.to_s
                    newItem.guid.content = Digest::MD5.hexdigest(item.to_s)
                    newItem.guid.isPermaLink = false
                end
            end
        end

        return rss
    end

end