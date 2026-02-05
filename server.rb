require "./database.rb"
require "./user.rb"
require "./downloader.rb"
require "./pipe.rb"
require "./block.rb"
require "./water.rb"
require "./rssboxblock.rb"
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
require "./blocks/shortenblock.rb"
require "./blocks/periscopeblock.rb"
require "./blocks/mixcloudblock.rb"
require "./blocks/svtplayblock.rb"
require "./blocks/ustreamblock.rb"
require "./blocks/speedrunblock.rb"
require "./blocks/soundcloudblock.rb"
require "./blocks/dailymotionblock.rb"
require "./blocks/vimeoblock.rb"
require "./blocks/twitchblock.rb"
require "./blocks/redditblock.rb"
require "./blocks/tabletojsonblock.rb"
require "./blocks/filterlangblock.rb"
require 'hashids'
require 'logutils'
require 'digest/md5'
require "sinatra/json"
require "securerandom"
require "dalli"
require "base64"

register Sinatra::BrowserID

# Disabling origin-check is needed to make webkit-browsers like Chrome work. 
# Behind a proxy you will also need to disable :remote_token, regardless for which browser.
set :protection, except: [:http_origin, :remote_token] 

set :browserid_button_class, "pure-button pure-button-primary"

helpers do

    include Rack::Utils
    alias_method :uh, :escape
    alias_method :h, :escape_html
            
    def protected!
        throw(:halt, [401, "Not authorized\n"]) unless authorized?
    end

    def encodeid(id)
        Hashids.new(ENV['PIPES_URL_SECRET'], 8).encode(id)
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

    def inlineSvg(svg)
        return 'data:image/svg+xml;base64,' + Base64.encode64('<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><g transform="scale(0.2)">' + svg + '</g></svg>')
    end

    # Return true if the rssbox environment variable is set
    def rssbox?
        ENV.has_key?('PIPES_RSSBOX')
    end

    # Return true if the rssbridge environment variable is set
    def rssbridge?
        ENV.has_key?('PIPES_RSSBRIDGE')
    end
end

configure do
    enable :sessions
    set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
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
        id = Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id)
    end
    if hashed_id.nil?
        # We restrict the number of maximum pipes according to the users plan
        return 402 if ! User.new(email: authorized_email).hasFreeStorage
    end
    return Hashids.new(ENV['PIPES_URL_SECRET'], 8).encode(Database.instance.storePipe(id: id, user: authorized_email, pipe: params[:pipe], preview: params[:preview]))
end

# endpoint to get a pipe json, or the pipe overview page
get %r{/pipe/(\w+)} do |hashed_id|
    if request.xhr?
        protected!
        return Database.instance.getPipe(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id))['pipe']
    else
        pipe = Database.instance.getPipe(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id))
        textinputs = JSON.parse(pipe['pipe'])['blocks'].select{|x| x['type'] == 'TextinputBlock' } || []
        erb :pipe, :locals => {:pipe => pipe, :textinputs => textinputs, :tags => Database.instance.getTags(), :owned => (pipe['user'].to_s == userEmailToId(authorized_email).to_s) }
    end
end

# endpoint to get a public pipe json
get %r{/publicpipe/(\w+)} do |hashed_id|
    Database.instance.getPublicPipe(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id))['pipe']
end

get %r{/pipename/(\w+)} do |hashed_id|
    protected!
    Database.instance.getPipe(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id))['title']
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
        Database.instance.setPipeTitle(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), user: authorized_email, title: params[:title])
    end
end

post %r{/pipedescription/(\w+)} do |hashed_id|
    protected!
    if params[:description]
        Database.instance.setPipeDescription(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), user: authorized_email, description: params[:description])
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
    mode = :xml # Default: Assume pipes carry RSS and thus xml
    if hashed_id[-4, 4] == '.txt'
        hashed_id[-4, 4] = ''
        mode = :txt
    end
    
    if hashed_id[-4, 4] == '.xml'
        hashed_id[-4, 4] = ''
        mode = :xml
    end

    if hashed_id[-5, 5] == '.json'
        hashed_id[-5, 5] = ''
        mode = :json
    end
    
    pipe = Pipe.new(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), params: params, user: User.new(email: authorized_email))
    
    output = pipe.run(mode: mode)
    if output.kind_of?(Water)
        output = output.solidify(mode)

        case mode
            when :txt then content_type 'text/plain'
            when :xml then content_type 'application/xml'
            when :json then content_type 'application/json'
        end
    else
        # help feed readers by adding the atom self element, used e.g. for image url replacement
        output = output.to_s.sub('<channel>', '<channel>' + "\n" + '<atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="self" type="application/rss+xml" href="' + 'https://www.pipes.digital/feed/' + pipe.encodedId() + '" />')

        case mode
            when :txt then content_type 'text/plain'
            when :xml then content_type 'application/rss+xml'
            when :json then content_type 'application/json'
        end
    end

    return output
end

# see the pipe output also in non-RSS supporting browsers like recently Firefox
get %r{/feedpreview/([\w\.]+)} do |hashed_id|
    pipe = Pipe.new(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), params: params, user: User.new(email: authorized_email))
    html = 'Timeout!'
    
    output = pipe.run(mode: :xml)
    if (output.kind_of?(Water))
        html = output.solidify
        if (output.orig_format == :xml)
            content_type 'text/xml'
        else
            content_type 'application/json'
        end
    else
        html = erb :feedpreview, :locals => {:feed => output, :hashed_id => pipe.encodedId() }
    end
    GC.start
    html
end

# endpoint to get a block output
# NOTE: this should be a GET semantically, but that breaks for longer pipes on the prod server (reason unknown)
post %r{/block/(\w+)} do |block_id|
    protected!
    pipejson = params[:pipe]
    
    pipe = Pipe.new(pipe: pipejson, start: block_id, user: User.new(email: authorized_email))
    output = pipe.run
    if params[:gallery]
        pipe = Pipe.new(pipe: pipejson, start: params['input_id'], user: User.new(email: authorized_email))
        input = pipe.run    # we might need the input to create absolute urls
        baseURL = Nokogiri::HTML(input.to_s).css("link[rel='canonical']").first&.attr('href')
        if baseURL
            baseURL = URI.parse(baseURL)
            baseURL.query = baseURL.fragment = nil
            baseURL = baseURL.to_s.delete_suffix('/')
        end
        
        feed = Nokogiri::XML(output.to_s)
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
    if output.respond_to?(:data)
        # This is a pipe with Water in it, meaning we can return the data as well as the json paths
        # used for autocomplete
        content_type :json
        return json({ data: output.data, paths: output.outline })
    end
    # If we are here, this is a pipe without Water, so the output is an RSS object
    return output.to_s
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
    Database.instance.sharePipe(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), user: authorized_email)
end

post %r{/unsharePipe/(\w+)} do |hashed_id|
    protected!
    Database.instance.unsharePipe(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), user: authorized_email)
end

post %r{/deletePipe/(\w+)} do |hashed_id|
    protected!
    Database.instance.deletePipe(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), user: authorized_email)
end

post %r{/copyPipe/(\w+)} do |hashed_id|
    protected!
    Hashids.new(ENV['PIPES_URL_SECRET'], 8).encode(Database.instance.copyPipe(id: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), user: authorized_email))
end

post %r{/like/(\w+)} do |hashed_id|
    protected!
    Database.instance.likePipe(user: authorized_email, pipe: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id))
end

post %r{/unlike/(\w+)} do |hashed_id|
    protected!
    Database.instance.unlikePipe(user: authorized_email, pipe: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id))
end

post %r{/addTag/(\w+)} do |hashed_id|
    protected!
    Database.instance.addTag(user: authorized_email, pipe: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), :tag => params[:tag])
end

post %r{/removeTag/(\w+)} do |hashed_id|
    protected!
    Database.instance.removeTag(user: authorized_email, pipe: Hashids.new(ENV['PIPES_URL_SECRET'], 8).decode(hashed_id), :tag => params[:tag])
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

post '/deleteAccount' do
    protected!
    if params['confirm'] == "I am sure"
        User.new(email: authorized_email).deleteUser!
    end
    logout!
end

get '/goodbye' do
    erb :goodbye
end

# webhook endpoint for the webhook block in pipes. General requirements:
#  1. Store only for something like 1 hour
#  2. Rate limit here or at nginx level
#  3. Each webhook post becomes the content of the blocks rss feed
post %r{/hook/(\w+)} do |hook_id|
    Database.instance.storeHook(content: request.body.read.to_s, blockid: hook_id.to_s);
end