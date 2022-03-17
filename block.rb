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

    # get the pipe by calling the children, which means its output will be ready
    # for our process function, which uses it as input
    def run
        processedInputs = []
        inputs.each {|input| processedInputs << input&.run }

        # here we override the userinput with the content of the textinput block, as those have priority
        textinputs&.each_with_index do |textinput, i|
            textinput = textinput&.run
            options[:userinputs][i] = textinput if textinput
        end
        return self.process(processedInputs)
    end

    # the core function that manipulates the inputs
    def process(inputs)
        return inputs[0]    # the root node will have only one child, and only has to echo it
    end

    # Transfer data from the old feedparser item of an input feed to the new regular rss item of the output feed
    def transferData(newItem, oldItem)
        newItem.title = oldItem.title
        if oldItem.updated
            newItem.updated = oldItem.updated.to_s
        end
        newItem.pubDate = oldItem.published.to_s if oldItem.published
        if (oldItem.url && oldItem.url != '')
            newItem.link = oldItem.url
        else
            newItem.link = '' # the rss won't get emitted if description is empty
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
        return newItem
    end
end