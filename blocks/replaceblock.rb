require 'rss'   
require 'feedparser'
require 'to_regexp'
require 'janeway'

class Replaceblock < Block
    def process(inputs)
        feed = inputs[0]
        pattern = self.options[:userinputs][0] if self.options[:userinputs]
        replace = self.options[:userinputs][1] if self.options[:userinputs]
        if self.options[:userinputs] && self.options[:userinputs][2] 
            field = self.options[:userinputs][2]
        else
            field = 'all'
        end

        begin
            regexp = pattern.to_regexp(detect: true)
        rescue RegexpError => re
            return self.errorFeed('Invalid regexpression', re.message)
        rescue NoMethodError => nme
            return self.errorFeed('Could not interpret pattern as regular expression', nme.message)
        end

        return inputs[0] if regexp.nil?
        rss = ""

        begin
            # NOTE: timeout might lead to instability. But pipes is already instable because this code deadlocked without the timeout, so this is a hail marry try to get the server more stable
            Timeout::timeout(10) {
                rss = RSS::Maker.make("rss2.0") do |maker|
                    self.transferChannel(maker, feed)
                   
                    feed.items.each do |item|
                        maker.items.new_item do |newItem|
                            if timeout?
                                next
                            end
                            case field
                            when 'all'
                                item.title = item.title.gsub(regexp, replace) if item.title
                                item.content_encoded = item.content.gsub(regexp, replace) if item.content
                                item.description = item.summary.gsub(regexp, replace) if item.summary && ! item.summary.empty?
                            when 'title' then item.title = item.title.gsub(regexp, replace) if item.title
                            when 'content' then item.content_encoded = item.content.gsub(regexp, replace) if item.content
                            when 'summary' then item.description= item.summary.gsub(regexp, replace) if item.summary && ! item.summary.empty?
                            when 'guid'
                                item.guid = item.guid.content.gsub(regexp, replace) if item.guid
                            end
                            newItem = transferData(newItem, item)
                        end
                        if timeout?
                            break
                        end
                    end
                end
            }
        rescue Timeout::Error
            warn "timeout error in replace block"
            return self.errorFeed('Replace block timed out', 'The replacement operation took too long and triggered a safeguard. Please try it with less data or email support.')
        end

        return rss
        
    end
end
    
class WateredReplaceblock < WateredBlock
    def process(inputs)
        water = inputs[0]
        pattern = self.options[:userinputs][0]
        replace = self.options[:userinputs][1]
        targetField = self.options[:userinputs][2]
        targetField = '$..*' if targetField.nil?

        begin
            regexp = pattern.to_regexp(detect: true)
        rescue RegexpError => re
            return self.errorFeed('Invalid regexpression', re.message)
        end

        return inputs[0] if regexp.nil?
        
        Janeway.enum_for(targetField, water.data).replace do |field|
            if (field.kind_of?(String))
                field.gsub(regexp, replace)
            else
                field
            end
        end

        return water
       
    end
end