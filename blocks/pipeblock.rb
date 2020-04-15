class Pipeblock < Block
    def process(inputs)
        if self.options[:userinputs]
            hashed_id = self.options[:userinputs][0]
        end

        pipe = Pipe.new(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id))
        return pipe.run

    end

end