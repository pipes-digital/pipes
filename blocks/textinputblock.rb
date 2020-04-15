class Textinputblock < Block
    def process(inputs)

        if self.options[:userinputs]
            name = self.options[:userinputs][0]
            default = self.options[:userinputs][1]
        end

        # TODO: The inspector does not show output of pieps that have textinput blocks. It should use its default

        return default
    end


end