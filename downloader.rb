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
        url = Addressable::URI.parse(url)
        result, date = Database.instance.getCache(key: 'url_' + url.to_s + '_' + js.to_s)
        if date.nil? || (date + 600) < Time.now.to_i
            @@limiters[url.host] = ThrottleQueue.new 0.4 if ! @@limiters[url.host]
            result = ""
            @@limiters[url.host].foreground(rand) {
                result = _get(url, js)
            }

            Database.instance.cache(key: 'url_' + url.to_s + '_' + js.to_s, value: result)
        end
        return result        
    end

    def _get(url, js)
        if js
            begin
                session = Capybara::Session.new(:selenium_chrome_headless)
                session.visit(url)
                return session.body
            ensure
                session.driver.quit
            end
        else
            begin
                response = HTTParty.get(url)
                if response.code == 429
                    if response.headers['retry-after'].to_i < 20
                        sleep response.headers['retry-after'].to_i
                        response = HTTParty.get(url)
                        result = response.body
                    else
                        result = ""
                    end
                else
                    result = response.body
                end
            rescue SocketError => se
                result = ""
                warn se
            rescue OpenSSL::SSL::SSLError => ssle
                result = ""
                warn ssle
            end
        end
        return result
    end

end