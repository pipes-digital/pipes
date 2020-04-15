require 'twitter'
require 'singleton'
require 'throttle-queue'

class TwitterClient
    include Singleton

    attr_accessor :throttle_timeline
    attr_accessor :throttle_search
    attr_accessor :client
    attr_accessor :initialized

    def init
        unless self.initialized
            self.initialized = true
                                    # rate limit / rate window (in seconds)W
            self.throttle_search = ThrottleQueue.new (450 / 900.0)
            self.throttle_timeline = ThrottleQueue.new (1500 / 900.0)
            self.client = Twitter::REST::Client.new do |config|
                config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
                config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
                config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
                config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
            end
        end
    end

    def timeline(user)
        init
        tweets = []
        self.throttle_timeline.foreground(rand) {
            tweets = self.client.user_timeline(user)
        }
        return tweets
    end

    def search(term)
        init
        tweets = []
        self.throttle_search.foreground(rand) {
            tweets = self.client.search(term)
        }
        return tweets
    end

    
end