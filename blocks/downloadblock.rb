require 'addressable/uri'

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
        
        # Validate URL before downloading
        begin
            parsed_url = Addressable::URI.parse(url)
            unless parsed_url && parsed_url.scheme =~ /^https?$/i
                return "<html><body>Error: Only HTTP and HTTPS URLs are allowed</body></html>"
            end
            # Prevent SSRF attacks by blocking private IP ranges
            if parsed_url.host =~ /^(127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|localhost)/i
                return "<html><body>Error: Access to private networks is not allowed</body></html>"
            end
        rescue => e
            return "<html><body>Error: Invalid URL provided</body></html>"
        end
        
        return Downloader.new.get(url, js)

    end

end