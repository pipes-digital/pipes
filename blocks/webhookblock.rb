class Webhookblock < Block
    def process(inputs)
        hooks = Database.instance.getHooks(blockid: self.id)
        
        rss = RSS::Maker.make("rss2.0") do |maker|
            maker.channel.title = 'Webhook'
            if (hooks && hooks.last)
                maker.channel.updated = hooks.last['date']
            else
                maker.channel.updated = Time.at(0).to_datetime.to_s
            end
            maker.channel.description = ' ' # the rss won't get emitted if description is empty
            maker.channel.link = ' ' # TODO: Set pipe url

            hooks.each do |item|
                maker.items.new_item do |newItem|
                    newItem.title = 'webhook'
                    newItem.updated = item['date']
                    newItem.link = ''
                    newItem.content_encoded = item['content']
                    newItem.guid.content = Digest::MD5.hexdigest(item['content'] + self.id)
                    newItem.guid.isPermaLink = false
                end
            end
        end

        return rss.to_s
    end

end