class Pipeblock < Block
    def process(inputs)
        if self.options[:userinputs]
            hashed_id = self.options[:userinputs][0]
        end

        pipe = Pipe.new(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), user: nil)
        return pipe.run

    end

end