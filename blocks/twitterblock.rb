require './twitterclient.rb'

class Twitterblock < Block
    USER = /^@/ 
    
    def process(inputs)

        selector = self.options[:userinputs][0]
        
        if (! selector || selector.nil? || selector.empty?)
            return '<rss version="2.0"><channel><title>Twitter Search term needed</title><link></link><description>Please enter something into the twitter block.</description></channel></rss>'
        end

        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.updated = Time.now
                
            maker.channel.link = ' '
            maker.channel.description = ' ' # the rss won't get emitted if description is empty

            begin
                if (selector =~ USER)
                    tweets = TwitterClient.instance.timeline(selector.gsub('@', ''))
                    maker.channel.title = "Tweets of " + selector
                else
                    # Seems to work for hashtags and regular search terms
                    tweets = TwitterClient.instance.search(selector)
                    maker.channel.title = "Searching Tweets with " + selector
                end
            rescue Twitter::Error::NotFound
                return '<rss version="2.0"><channel><title>Twitter Page not found</title><link></link><description>Could find no tweets for this term.</description></channel></rss>'
            end

            tweets.each do |tweet|
                maker.items.new_item do |newItem|
                    newItem.title = "Tweet"

                    newItem.updated = tweet.created_at
                    
                    newItem.link = tweet.url

                    newItem.author = tweet.user.name
                   
                    newItem.content_encoded = tweet.full_text
                    newItem.guid.content = tweet.url
                    newItem.guid.isPermaLink = true
                end
            end
        end

        return rss.to_s
        
    end
end