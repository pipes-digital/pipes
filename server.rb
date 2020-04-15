require "./database.rb"
require "./user.rb"
require "./downloader.rb"
require "./pipe.rb"
require "./block.rb"
require "./blocks/feedblock.rb"
require "./blocks/filterblock.rb"
require "./blocks/duplicateblock.rb"
require "./blocks/combineblock.rb"
require "./blocks/uniqueblock.rb"
require "./blocks/truncateblock.rb"
require "./blocks/sortblock.rb"
require "./blocks/downloadblock.rb"
require "./blocks/extractblock.rb"
require "./blocks/builderblock.rb"
require "./blocks/pipeblock.rb"
require "./blocks/webhookblock.rb"
require "./blocks/replaceblock.rb"
require "./blocks/textinputblock.rb"
require "./blocks/twitterblock.rb"
require "./blocks/mergeblock.rb"
require "./blocks/insertblock.rb"
require "./blocks/foreachblock.rb"
require "./blocks/imagesblock.rb"
require 'hashids'
require 'logutils'
require 'digest/md5'
require 'thread/pool'
require "sinatra/json"

pool = Thread.pool(1)
set :browserid_button_class, "pure-button pure-button-primary"

helpers do

    include Rack::Utils
    alias_method :uh, :escape
    alias_method :h, :escape_html
            
    def protected!
        throw(:halt, [401, "Not authorized\n"]) unless authorized?
    end

    def encodeid(id)
        Hashids.new("asdqwrwqr34pipes", 8).encode(id)
    end

    def gravatar
        begin
            email_address = authorized_email.downcase
        rescue
            return "https://www.gravatar.com/avatar/0000?d=mm"
        end
        hash = Digest::MD5.hexdigest(email_address)
        return "https://www.gravatar.com/avatar/#{hash}?d=mm"
    end

    def userEmailToId(email)
        begin
            return Database.instance.getUserId(email: email)
        rescue
        end
        return nil
    end

    def plan
        User.new(email: authorized_email).plan
    end

    def paramsToArgs(params:)
        url = ""
        unless params.empty?
            url = "?"
            params.each do |k,v|
                begin
                    url += CGI.escape(k) + '=' + CGI.escape(v) + "&"
                rescue
                end
            end
        end
        return url
    end
end

configure do
    # disable remote token for persona behind nginx proxy, http origin for webkit browsers and portier
    set :protection, except: [:remote_token, :http_origin]
    pool.process {
        while true
            Database.instance.cleanHooks
            Database.instance.cleanCache
            sleep 3605
        end
    }
end

LogUtils::Logger.root.level = :warn

get '/' do
    if authorized?
        redirect '/mypipes'
    else
        erb :index
    end
end

get '/editor' do
    erb :editor, :locals => {:hashed_id => nil, :pipes => Database.instance.getPipes(user: authorized_email), :fork_id => params[:fork]}
end

get %r{/editor/(\w+)} do |hashed_id|
    erb :editor, :locals => {:hashed_id => hashed_id, :pipes => Database.instance.getPipes(user: authorized_email), :fork_id => nil}
end

post '/pipe' do
    protected!
    hashed_id = params[:id]
    hashed_id = nil if params[:id] == 'undefined'
    if hashed_id
        id = Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id)
    end
    if hashed_id.nil?
        # We restrict the number of maximum pipes according to the users plan
        return 402 if ! User.new(email: authorized_email).hasFreeStorage
    end
    return Hashids.new("asdqwrwqr34pipes", 8).encode(Database.instance.storePipe(id: id, user: authorized_email, pipe: params[:pipe], preview: params[:preview]))
end

# endpoint to get a pipe json, or the pipe overview page
get %r{/pipe/(\w+)} do |hashed_id|
    if request.xhr?
        protected!
        return Database.instance.getPipe(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id))['pipe']
    else
        pipe = Database.instance.getPipe(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id))
        textinputs = JSON.parse(pipe['pipe'])['blocks'].select{|x| x['type'] == 'TextinputBlock' } || []
        erb :pipe, :locals => {:pipe => pipe, :textinputs => textinputs, :tags => Database.instance.getTags(), :owned => (pipe['user'].to_s == userEmailToId(authorized_email).to_s) }
    end
end

# endpoint to get a public pipe json
get %r{/publicpipe/(\w+)} do |hashed_id|
    Database.instance.getPublicPipe(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id))['pipe']
end

get %r{/pipename/(\w+)} do |hashed_id|
    protected!
    Database.instance.getPipe(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id))['title']
end

get '/mypipes' do
    if authorized?
        erb :mypipes, :locals => {:pipes => Database.instance.getPipes(user: authorized_email), :likes => Database.instance.getLikes(user: authorized_email)}
    else
        erb :login, :locals => {:target => '/mypipes'}
    end
end

get '/mainlogin' do
    target = params['target'] || '/'
    if authorized?
        puts 'authorized'
        redirect target
    else
        puts 'not authorized'
        erb :login, :locals => {:target => target}
    end
end

post %r{/pipetitle/(\w+)} do |hashed_id|
    protected!
    if params[:title]
        Database.instance.setPipeTitle(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), user: authorized_email, title: params[:title])
    end
end

post %r{/pipedescription/(\w+)} do |hashed_id|
    protected!
    if params[:description]
        Database.instance.setPipeDescription(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), user: authorized_email, description: params[:description])
    end
end

get '/login' do
    target = params['target'] || '/editor#save'
    erb :login_modal, :locals => {:target => target }
end

post '/logout' do
    logout!

    redirect back
end

# endpoint to get the pipe output
get %r{/feed/([\w\.]+)} do |hashed_id|
    mode = :xml
    if hashed_id[-4, 4] == '.txt'
        hashed_id[-4, 4] = ''
        mode = :txt
    else
        content_type 'application/rss+xml'
    end
    pipe = Pipe.new(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), params: params)
    
    return pipe.run(mode: mode)
end

# see the pipe output also in non-RSS supporting browsers like recently Firefox
get %r{/feedpreview/([\w\.]+)} do |hashed_id|
    pipe = Pipe.new(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), params: params)
    pipe_output = pipe.run(mode: :xml)
    feed = FeedParser::Parser.parse(pipe_output)
    erb :feedpreview, :locals => {:feed => feed, :hashed_id => hashed_id } 
end

# endpoint to get a block output
# NOTE: this should be a GET semantically, but that breaks for longer pipes on some servers
post %r{/block/(\w+)} do |block_id|
    protected!
    pipejson = params[:pipe]
    pipe = Pipe.new(pipe: pipejson, start: block_id)
    output = pipe.run
    if params[:gallery]
        pipe = Pipe.new(pipe: pipejson, start: params['input_id'])
        input = pipe.run    # we might need the input to create absolute urls
        baseURL = Nokogiri::HTML(input).css("link[rel='canonical']").first&.attr('href')
        if baseURL
            baseURL = URI.parse(baseURL)
            baseURL.query = baseURL.fragment = nil
            baseURL = baseURL.to_s.delete_suffix('/')
        end
        
        feed = Nokogiri::XML(output)
        images = feed.xpath('//item/content:encoded')
        images = images.map do |x|
            doc = Nokogiri::HTML(x.content)
            img = doc.css('img').first    # nokogiri put the img element in a new html document
            img.remove_attribute('width')
            img.remove_attribute('height')
            img.remove_attribute('style')
            img.remove_attribute('onclick')
            img.remove_attribute('srcset')  # This might be nice to use later, if we can covnert it into absolute urls
            
            if img.attr('src').to_s.start_with?('/')
                # we know it's not an absolute url, which happens often when it does not come from a feed
                
                if baseURL
                    img['src'] = baseURL + img.attr('src')
                end
            end
            img
        end
        output = erb :gallery, :locals => {:images => images}
    end
    return output
end

get '/settings' do
    if authorized?
        erb erb :settings
    else
        erb :login, :locals => {:target => '/settings'}
    end
    
end

get '/pipes' do
    if request.xhr?
        protected!
        pipes = Database.instance.getPipes(user: authorized_email)
        output = pipes.map{|x| {id: encodeid(x['id']), title: x['title']} }
        json output
    else
        order = params[:order] || 'likes'
        page = params[:page] || 0
        tag = params[:tag]
        tag = nil if tag&.empty?
        erb :pipes, :locals => {:pipes => Database.instance.getPublicPipes(order: order, :tag => tag), :likedpipes => Database.instance.getLikedPipes(user: authorized_email), :tags => Database.instance.getTags(), :tag => tag, :page => page}
    end
end

post %r{/sharePipe/(\w+)} do |hashed_id|
    protected!
    Database.instance.sharePipe(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), user: authorized_email)
end

post %r{/unsharePipe/(\w+)} do |hashed_id|
    protected!
    Database.instance.unsharePipe(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), user: authorized_email)
end

post %r{/deletePipe/(\w+)} do |hashed_id|
    protected!
    Database.instance.deletePipe(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), user: authorized_email)
end

post %r{/copyPipe/(\w+)} do |hashed_id|
    protected!
    Hashids.new("asdqwrwqr34pipes", 8).encode(Database.instance.copyPipe(id: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), user: authorized_email))
end

post %r{/like/(\w+)} do |hashed_id|
    protected!
    Database.instance.likePipe(user: authorized_email, pipe: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id))
end

post %r{/unlike/(\w+)} do |hashed_id|
    protected!
    Database.instance.unlikePipe(user: authorized_email, pipe: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id))
end

post %r{/addTag/(\w+)} do |hashed_id|
    protected!
    Database.instance.addTag(user: authorized_email, pipe: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), :tag => params[:tag])
end

post %r{/removeTag/(\w+)} do |hashed_id|
    protected!
    Database.instance.removeTag(user: authorized_email, pipe: Hashids.new("asdqwrwqr34pipes", 8).decode(hashed_id), :tag => params[:tag])
end

post '/mailchange' do
    protected!
    success = false
    if (params['newmail'] && params['newmail_confirmation'] && params['newmail'] == params['newmail_confirmation'])
        success = Database.instance.changeMail(new: params['newmail'], old: authorized_email)
    end
    if success
        redirect '/settings#mailchange'
    else
        redirect '/settings#mailchange_fail'
    end
end

get '/export' do
    protected!
    headers['Content-Disposition'] = 'attachment'
    content_type 'application/json'
    User.new(email: authorized_email).export()
end



# webhook endpoint for the webhook block in pipes. General requirements:
#  1. Store only for something like 1 hour
#  2. Rate limit here or at nginx level
#  3. Each webhook post becomes the content of the blocks rss feed
post %r{/hook/(\w+)} do |hook_id|
    Database.instance.storeHook(content: request.body.read.to_s, blockid: hook_id.to_s);
end