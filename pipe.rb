require 'date'

class Pipe

    # the final output block that has to return a feed. Its run-function will call all children block, who will do the same
    attr_accessor :output
    attr_accessor :title
    attr_accessor :starttime
    attr_accessor :user
    attr_accessor :id
    # true if the pipe uses data blocks (instead of classic RSS blocks) in the end
    attr_accessor :watered

    def initialize(id: nil, pipe: nil, start: nil, params: {}, user:)
        if (id)
            stored_data = Database.instance.getPipe(id: id)
            pipe = JSON.parse(stored_data['pipe'])
            self.title = stored_data['title']
            root = pipe['blocks'].detect{|x| x['id'] == 'output' }
            self.output = Block.new
        else
            pipe = JSON.parse(pipe)
            root = pipe['blocks'].detect{|x| x['id'] == start }
            if start == 'output'
                self.output = Block.new
            else
                self.output = createBlock(root, params)
            end
            id = :temp
        end
        
        self.output.inputs = createInputs(root['inputs'], pipe, params)
        @id = id
        @params = params
        @watered = self.output.inputs.first.kind_of?(WateredBlock)
        self.user = user
    end

    def encodedId()
        return Hashids.new(ENV['PIPES_URL_SECRET'], 8).encode(@id) unless @id == :temp
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
            when 'ShortenBlock' then ShortenBlock.new
            when 'PeriscopeBlock' then PeriscopeBlock.new
            when 'MixcloudBlock' then MixcloudBlock.new
            when 'SpeedrunBlock' then SpeedrunBlock.new
            when 'UstreamBlock' then UstreamBlock.new
            when 'DailymotionBlock' then DailymotionBlock.new
            when 'SoundcloudBlock' then SoundcloudBlock.new
            when 'SvtplayBlock' then SvtplayBlock.new
            when 'VimeoBlock' then VimeoBlock.new
            when 'TwitchBlock' then TwitchBlock.new
            when 'RedditBlock' then RedditBlock.new
            when 'TabletojsonBlock' then TabletojsonBlock.new
            when 'FilterlangBlock' then FilterlangBlock.new
            when 'WateredDownloadBlock' then WateredDownloadblock.new
            when 'WateredFilterBlock' then WateredFilterblock.new
            when 'WateredDuplicateBlock' then WateredDuplicateblock.new
            when 'WateredReplaceBlock' then WateredReplaceblock.new
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
        self.starttime = Time.now
        if @id == :temp
            return output.run
        else
            id = @id.to_s + mode.to_s + Digest::SHA1.hexdigest(@params.to_s)
            resultRaw = Database.instance.getCache(key: id)
            if resultRaw.nil?
                result = ''
                result = output.run
                if result.kind_of?(Water)
                    Database.instance.cache(key: id, value: result.solidify(mode))
                else
                    if mode == :txt
                        begin
                            doc = Nokogiri::XML(result.to_s)
                            contents = doc.xpath('//item/content:encoded')
                            result = contents.map{|x| x.content.strip }.join("\n")
                        rescue Nokogiri::XML::XPath::SyntaxError
                        end
                    end
                    
                    Database.instance.cache(key: id, value: result.to_s)
                end
            else
                if @watered
                    result = Water.new.absorb(resultRaw)
                else
                    if (mode == :xml)
                        result = RSS::Parser.parse(resultRaw)
                    else
                        result = resultRaw
                    end
                end
            end
            return result
        end
    end
end