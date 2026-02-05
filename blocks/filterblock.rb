require 'rss'
require 'feedparser'
require 'to_regexp'
require 'json'
require 'janeway'

# Regular filter block, assumes that input is a RSS feed object
class Filterblock < Block
    def process(inputs)
        feed = inputs[0]

        filter = self.options[:userinput] if self.options[:userinput]
        filter = self.options[:userinputs][0] if self.options[:userinputs]
        blockMode = self.options[:userinputs][1] if self.options[:userinputs]
        field = self.options[:userinputs][2] if self.options[:userinputs]

        return inputs[0] if filter.empty?

        rss = RSS::Maker.make("rss2.0") do |maker|
            self.transferChannel(maker, feed)

            feed.items.each do |item|
                begin
                    regexp = filter.to_regexp(detect: true)
                rescue RegexpError => re
                    return self.errorFeed('Invalid regexpression', re.message)
                end
                case field
                    when 'all' then accept = ! (item.content&.match(regexp).nil? && item.title&.match(regexp).nil? && item.summary&.match(regexp).nil? && item.description&.match(regexp).nil? && item.url&.match(regexp).nil? && (! item.categories.any?{|x| ! (x.content&.match(regexp).nil? && x.domain&.match(regexp).nil?) })) 
                    when 'title' then accept = ! (item.title&.match(regexp).nil?)
                    when 'summary' then accept = ! (item.summary&.match(regexp).nil?)
                    when 'description' then accept = ! (item.description&.match(regexp).nil?)
                    when 'content' then accept = ! (item.content&.match(regexp).nil?)
                    when 'link' then accept = ! (item.url&.match(regexp).nil?)
                    when 'author' then accept = ! (item.author&.name&.match(regexp).nil?)
                    when 'category' then accept = item.categories.any?{|x| ! (x.content&.match(regexp).nil? && x.domain&.match(regexp).nil?) }
                    else accept = ! (item.content&.match(regexp).nil? && item.title&.match(regexp).nil? && item.summary&.match(regexp).nil? && item.url&.match(regexp).nil?)
                end
                accept = ! accept if blockMode
                
                if accept
                    maker.items.new_item do |newItem|
                        newItem = transferData(newItem, item)
                    end
                end
            end
        end

        return rss
    end
end

# Dynamic filter block, assumes that input is a Water object, holding structured data
class WateredFilterblock < WateredBlock
    def process(inputs)
        water = inputs[0]

        # The field we potentially remove, e.g. /path/to/random/item
        targetField = self.options[:userinputs][0] if self.options[:userinputs]
        # To decide, we look at the content of this, e.g. item/description, or also just item (if not an array)
        controlField = self.options[:userinputs][1] if self.options[:userinputs]
        # The value we compare against, can also be a regexp
        filter = self.options[:userinputs][2] if self.options[:userinputs]
        # With this operation, e.g. 'contains' for regexp match mode
        operator = self.options[:userinputs][3] if self.options[:userinputs]
        
        case operator
            when 'contains'
                filter = '.*' + filter + '.*'
            when 'regexp' 
                begin
                    _ = filter.to_regexp(detect: true)
                rescue RegexpError => re
                    return self.errorFeed('Invalid regexpression', re.message)
                end
            when 'misses'
                filter = '^((?!' + filter + ').)*$'
        end

        selector = targetField
        unless controlField.empty?
            # Adding a match clause lets us delete the parent field with Janeway.delete_if
            selector += '[? (@.' + controlField + ' != "Nothing" || @.' + controlField + ' == "Nothing" )]'
        end

        Janeway.enum_for(selector, water.data).delete_if do |field|
            field = field[controlField] unless controlField.empty?
            if (field.kind_of?(Array)) 
                field.any?{|x| x.match?(Regexp.new(filter)) }
            else
                field.match?(Regexp.new(filter))
            end
        end

        return water
    end
    
end