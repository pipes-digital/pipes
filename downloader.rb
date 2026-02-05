require 'httparty'
require 'throttle-queue'
require 'addressable/uri'

# Download and cache downloads. Limit requests to the same domain to not spam it

class Downloader

    def initialize()
        begin
            @@limiters
        rescue
            @@limiters = {}
        end
    end

    def get(url, js = false)
        url = Addressable::URI.parse(url).normalize
        unless url.scheme =~ /^https?$/i
            warn "non-http url not allowed, was: #{url}"
            return ''
        end
        if url.host =~ /^(127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|localhost)/i
            warn "Access to private networks is not allowed, was: #{url}"
            return ''
        end
        result = Database.instance.getCache(key: 'url_' + url.to_s + '_' + js.to_s)
        if result.nil?
            @@limiters[url.host] = ThrottleQueue.new 0.4 if ! @@limiters[url.host]
            result = ""
            @@limiters[url.host].foreground(rand) {
                result = Database.instance.getCache(key: 'url_' + url.to_s + '_' + js.to_s)
                if (result.nil?) # not cached in the meantime
                    result = _get(url, js)
                    Database.instance.cache(key: 'url_' + url.to_s + '_' + js.to_s, value: result)
                end
            }
            
        end
        return result        
    end

    def _get(url, js)
        url = url.to_s.gsub('%3B', ';') # %3B is not understood by all web servers
        if js
            begin
                browser = Ferrum::Browser.new
                browser.go_to(url)
                return browser.body
            rescue Ferrum::TimeoutError
                return "Timeout!"
            ensure
                browser.quit
            end
        else
            begin
                response = HTTParty.get(url, {headers: {"User-Agent" => "Pipes/1.0"}, timeout: 5})
                if response.code == 429
                    if response.headers['retry-after'].to_i < 20
                        sleep response.headers['retry-after'].to_i
                        response = HTTParty.get(url, {headers: {"User-Agent" => "Pipes/1.0"}})
                        result = response.body
                    else
                        result = ""
                    end
                else
                    result = response.body
                end
            rescue SocketError => se
                result = "Socket Error!"
                warn se
            rescue OpenSSL::SSL::SSLError => ssle
                result = "SSL Error!"
                warn ssle
            rescue Net::ReadTimeout => nrt
                result = "Timeout!"
                warn nrt.message
            rescue Net::OpenTimeout => netot
                result = "Timeout!"
                warn netot.message
            end
            
        end
        return result
    end

end