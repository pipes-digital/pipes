class Pipe

    # the final output block that has to return a feed. Its run-function will call all children block, who will do the same
    attr_accessor :output
    attr_accessor :title

    def initialize(id: nil, pipe: nil, start: nil, params: {})
        if (id)
            stored_data = Database.instance.getPipe(id: id)
            pipe = JSON.parse(stored_data['pipe'])
            self.title = stored_data['title']
            root = pipe['blocks'].detect{|x| x['id'] == 'output' }
            self.output = Block.new
        else
            pipe = JSON.parse(pipe)
            root = pipe['blocks'].detect{|x| x['id'] == start }
            self.output = createBlock(root, params)
            id = :temp
        end
        self.output.inputs = createInputs(root['inputs'], pipe, params)
        @id = id
        @params = params
    end

    def encodedId()
        return Hashids.new("pipedypipe", 8).encode(@id) unless @id == :temp
        return "temp"
    end

    def createBlock(blockData, params)
        block = case blockData['type']
            when 'FeedBlock' then Feedblock.new
            when 'FilterBlock' then Filterblock.new
            when 'CombineBlock' then Combineblock.new
            when 'DuplicateBlock' then Duplicateblock.new
            when 'UniqueBlock' then Uniqueblock.new
            when 'TruncateBlock' then Truncateblock.new
            when 'SortBlock' then Sortblock.new
            when 'DownloadBlock' then Downloadblock.new
            when 'ExtractBlock' then Extractblock.new
            when 'BuilderBlock' then Builderblock.new
            when 'PipeBlock' then Pipeblock.new
            when 'WebhookBlock' then Webhookblock.new
            when 'ReplaceBlock' then Replaceblock.new
            when 'TextinputBlock' then Textinputblock.new
            when 'TwitterBlock' then Twitterblock.new
            when 'MergeBlock' then Mergeblock.new
            when 'InsertBlock' then Insertblock.new
            when 'ForeachBlock' then Foreachblock.new
            when 'ImagesBlock' then ImagesBlock.new
        end
        block.options[:userinput] = blockData['userinput'] if blockData['userinput']
        block.options[:userinputs] = blockData['userinputs'] if blockData['userinputs']

        block.pipe = self

        # NOTE: Should this block specific behaviour better be handled inside the block?
        case blockData['type']
            when 'TextinputBlock'
                if params[block.options[:userinputs][0]]
                    block.options[:userinputs][1] = params[block.options[:userinputs][0]]
                end
        end
        block.id = blockData['id']
        return block
    end

    def createInputs(inputs, pipe, params)
        blocks = []
        inputs.each do |input|
            if input['from']
                blockData = pipe['blocks'].detect{|x| x['id'] == input['from'] }
                block = createBlock(blockData, params)                
                block.inputs = createInputs(blockData['inputs'], pipe, params)
                block.textinputs = createInputs(blockData['textinputs'], pipe, params) if blockData['textinputs']
                blocks.push(block)
            else
                blocks.push(nil)
            end
        end
        return blocks
    end

    # execute the pipe
    def run(mode: :xml)
        if @id == :temp
            return output.run
        else
            id = @id.to_s + mode.to_s + Digest::SHA1.hexdigest(@params.to_s)
            result, date = Database.instance.getCache(key: id)
            if date.nil? || (date + 600) < Time.now.to_i
                result = output.run
                if mode == :txt
                    begin
                        doc = Nokogiri::XML(result)
                        contents = doc.xpath('//item/content:encoded')
                        result = contents.map{|x| x.content.strip }.join("\n")
                    rescue Nokogiri::XML::XPath::SyntaxError
                    end
                end
                
                Database.instance.cache(key: id, value: result)
            end
            return result
        end
    end
end