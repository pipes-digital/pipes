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
end