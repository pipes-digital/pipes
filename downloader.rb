require 'httparty'
require 'lru_redux'

# Download and cache downloads. Limit requests to the same domain to not spam it

class Downloader

    def initialize()
        begin
            @@limiter
        rescue
            @@limiter = LruRedux::TTL::ThreadSafeCache.new(1000, 2)
        end
    end

    def get(url, js = false)
        url = URI.parse(URI.escape(url))
        result, date = Database.instance.getCache(key: 'url_' + url.to_s + '_' + js.to_s)
        if date.nil? || (date + 600) < Time.now.to_i
            while (@@limiter.key?(url.host))
                sleep(2)
            end
            @@limiter[url.host] = 1

            if js
                session = Capybara::Session.new(:selenium_chrome_headless)
                session.visit(url)
                result = session.body
                session.driver.browser.close
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
            Database.instance.cache(key: 'url_' + url.to_s + '_' + js.to_s, value: result)
        end
        return result        
    end

end