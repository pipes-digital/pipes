class Downloadblock < Block
    def process(inputs)
        if self.options[:userinputs]
            url = self.options[:userinputs][0]
            js = false
            begin
                # this might not be available in old blocks or for free users
                js = self.options[:userinputs][1]
            end
        end
        return Downloader.new.get(url, js)

    end

end