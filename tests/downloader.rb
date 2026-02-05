require_relative '../downloader.rb'
require_relative '../database.rb'
require "test/unit"
 
class TestDownloader < Test::Unit::TestCase

    def setup
        Database.instance.testmode
    end

    # The downloader can download a site
    def test_downloader
        response = Downloader.new.get("https://www.onli-blogging.de/", false)
        assert_not_empty(response)
        assert_true(response.include?('onli-blogging'))
    end

    # The downloader waits when getting a repeat request
    def test_downloader_throttle
        url = "https://www.onli-blogging.de/"
        starttime = Time.now
        Database.instance.uncache(id: 'url_' + url + '_' + false.to_s)
        response1 = Downloader.new.get("https://www.onli-blogging.de/", false)
        Database.instance.uncache(id: 'url_' + url + '_' + false.to_s)
        response2 = Downloader.new.get("https://www.onli-blogging.de/", false)
        stoptime = Time.now
        
        assert_not_empty(response1)
        assert_true(response1.include?('onli-blogging'))
        assert_not_empty(response2)
        assert_true(response2.include?('onli-blogging'))
        assert_true((stoptime - starttime) > 1)
    end

    # The downloader waits when getting threaded repeat requests
    def test_downloader_throttle_threads
        url = "https://www.onli-blogging.de/"
        Database.instance.uncache(id: 'url_' + url + '_' + false.to_s)   # When cached there would be no throttle

        threads = []
        responses = []
        starttime = Time.now
        3.times do
            threads << Thread.new { responses << Downloader.new.get("https://www.onli-blogging.de/", false) }
        end
        threads.each(&:join)
        stoptime = Time.now
        
        assert_not_empty(responses)
        responses.each {|x| assert_not_empty(x) }
        responses.each {|x| assert_true(x.include?('onli-blogging')) }
        assert_true((stoptime - starttime) > 1, "The requests were not throttled")
        # Note: Initially the target time was shorter, as only the first request is supposed to be
        #       made. But parallel "requests" are currently still throttled, even if the later
        #       results come from the cache. So making the three calls will take a while.
        assert_true((stoptime - starttime) < 9, "The requests were throttled too much")
    end

    
 
end