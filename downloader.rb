require 'open-uri'
require 'open_uri_redirections'
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
                sleep(1)
            end
            @@limiter[url.host] = 1

            if js
                session = Capybara::Session.new(:selenium_chrome_headless)
                session.visit(url)
                result = session.body
                session.driver.browser.close
            else
                begin
                    result = open(url, :allow_redirections => :all).read
                rescue OpenURI::HTTPError => ohe
                    result = ""
                    warn ohe
                rescue OpenSSL::SSL::SSLError => ose
                    result = ""
                    warn ose
                end
            end
            Database.instance.cache(key: 'url_' + url.to_s + '_' + js.to_s, value: result)
        end
        return result        
    end

end