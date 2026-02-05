class Twitterblock < Block
    
    def process(inputs)
        return self.errorFeed('Twitter Block deactivated', 'With the API changes the twitter block had to be deactivated.')
    end
end