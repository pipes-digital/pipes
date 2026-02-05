require 'date'
require 'rss'

class RSS::Rss::Channel::Item
    # This is a compatibility shim for the blocks. Those priorly relied on their feeds going through feedparser, and being a feedparser object.
    # Now (for performance) we don't reparse them anymore and work with rss objects (from the rss gem) but still want the old getters to work.
    def content
        content_encoded
    end
    def updated
        pubDate
    end
    def summary
        description
    end
    def url
        link
    end
end



class Block

    # a recursive list of blocks that need to be processed before this block
    attr_accessor :inputs
    # a list of blocks that need to be processed before this block, that fill options.userinputs
    attr_accessor :textinputs
    # a hash with the options that change the behaviour of the block
    attr_accessor :options
    # the block id as generated in the editor (careful, user can manipulate that easily)
    attr_accessor :id

    # pipe object, used to inquire about user and meta data like the pipe title
    attr_accessor :pipe

    def initialize
        self.inputs = []
        self.options = {}
    end

    def timeout?
        limit = 10
        if ! pipe.nil?
            # pipe.user can also be nil, in the pipeblock for example
            limit = case pipe&.user&.plan
                when 'pro_v1' then 30
                when 'regular_v1' then 20
                else 10
            end
        end
        return (! pipe.nil?) && ((Time.now - pipe.starttime) > limit)
    end

    # get the pipe by calling the children, which means its output will be ready
    # for our process function, which uses it as input
    def run
        if timeout?
            # time out!
            puts "timeout for pipe #{self.pipe.id}"
            return self.errorFeed('Timeout', 'The pipe took too long to complete. Please try again later.')
        end
        processedInputs = []
        inputs.each {|input| processedInputs << input&.run }

        # here we override the userinput with the content of the textinput block, as those have priority
        textinputs&.each_with_index do |textinput, i|
            textinput = textinput&.run
            options[:userinputs][i] = textinput if textinput
        end
        return self.process(processedInputs.map{|x| inputFormat(x) })
    end

    # Hook to transform inputs into the data format this block understands. Will do nothing for
    # regular blocks, but will try to put the data into a Water objekt for Water blocks
    def inputFormat(input)
        return input
    end

    # the core function that manipulates the inputs
    def process(inputs)
        return inputs[0]    # the root node will have only one child, and only has to echo it
    end

    # Transfer data from the old (feedparser or rss) item of an input feed to the new rss maker item of the output feed
    def transferData(newItem, oldItem)
        if oldItem.class == FeedParser::Item
            # We got a feedparser object
            newItem.title = oldItem.title
            if oldItem.updated
                newItem.updated = oldItem.updated.to_s
            end
            newItem.pubDate = oldItem.published.to_s if oldItem.published
            if (oldItem.url && oldItem.url != '')
                newItem.link = oldItem.url
            else
                newItem.link = '' # the rss won't get emitted if link is null
            end
            newItem.content_encoded = oldItem.content
            newItem.guid.content = oldItem.guid
            newItem.guid.isPermaLink = oldItem.guid.include?('http')
            newItem.description = oldItem.summary if oldItem.summary && ! oldItem.summary.empty?
            newItem.author = oldItem.author if oldItem.author
            if oldItem.attachments?
                newItem.enclosure.url = oldItem.attachment.url
                newItem.enclosure.length = oldItem.attachment.length
                newItem.enclosure.type = oldItem.attachment.type
                if (newItem.description.nil? || newItem.description.empty?) && oldItem.attachment.description
                    newItem.description = oldItem.attachment.description.gsub(/\n/,"<br />\n")
                end
            end
            oldItem.categories.each do |category|
                target = newItem.categories.new_category
                target.content = category.name
                target.domain = category.scheme
            end
        else
            newItem.title = oldItem.title
            newItem.updated = oldItem.updated
            newItem.link = oldItem.link if oldItem.link
            newItem.content_encoded = oldItem.content_encoded
            newItem.guid.content = oldItem.guid&.content
            newItem.guid.isPermaLink = oldItem.guid.content&.include?('http') if oldItem.guid&.content
            newItem.description = oldItem.description
            newItem.author = oldItem.author
            if (oldItem.enclosure)
                newItem.enclosure.url = oldItem.enclosure.url
                newItem.enclosure.length = oldItem.enclosure.length
                newItem.enclosure.type = oldItem.enclosure.type
                newItem.enclosure.description = oldItem.enclosure.description if oldItem.enclosure.respond_to?(:description) && oldItem.enclosure.description
            end
            oldItem.categories.each do |category|
                target = newItem.categories.new_category
                target.content = category.content
                target.domain = category.domain
            end
        end
        return newItem
    end

    # Transfer the main channel data (without the items) of an rss object to an rss maker
    def transferChannel(maker, feed)
        maker.channel.updated = feed.channel.pubDate
        maker.channel.link = feed.channel.link

        maker.channel.title = feed.channel.title
        if (feed.channel.title.empty?)
            maker.channel.link = ' ' # the rss won't get emitted if link is empty
        end

        maker.channel.description = feed.channel.description
        if (feed.channel.description.empty?)
            maker.channel.description = ' ' # the rss won't get emitted if description is empty
        end

        if (feed&.channel&.image)
            maker.image.url = feed.channel.image.url
            maker.image.title =  feed.channel.image.title
            maker.image.width = feed.channel.image.width if feed.channel.image.width
            maker.image.height = feed.channel.image.height if feed.channel.image.height
            maker.image.description = feed.channel.image.description
        end
    end

    def errorFeed(title, message)
        if self.kind_of?(Textinputblock)
            # Text input blocks that time out should only return a string
            return message
        else
            # other blocks can return a full RSS feed
            rss = RSS::Maker.make("rss2.0") do |maker|
                maker.channel.updated = Time.now
                    
                maker.channel.link = ' '
                maker.channel.description = message 
                maker.channel.title = title
            end

            return rss
        end
    end
end

class WateredBlock < Block
    # Hook to transform inputs into the data format this block understands. Will do nothing for
    # regular blocks, but will try to put the data into a Water objekt for Water blocks
    def inputFormat(input)
        unless (input.kind_of?(Water) || input.nil?)
            return Water.new.absorb(input)
        end
        return input
    end
end