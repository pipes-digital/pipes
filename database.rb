require 'sqlite3'
require 'singleton'
require 'sanitize'
require 'dalli'
require 'json'

class Database
    include Singleton

    attr_reader :db
    attr_reader :dc
    
    def initialize
        self.setupDB(:file)
    end

    # Activate testmode, which means re-initializing the sqlite databases in memory
    def testmode
        self.setupDB(:memory)
    end

    def setupDB(mode)
        if (mode == :file)
            @db = SQLite3::Database.new "pipes.db"
        else
            @db = SQLite3::Database.new ":memory:"
        end

        begin
            @db.execute 'CREATE TABLE IF NOT EXISTS users(
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            email TEXT UNIQUE
            );'
            
            @db.execute 'CREATE TABLE IF NOT EXISTS plans(
                            plan TEXT,
                            user INTEGER,
                            subscription_id TEXT,
                            FOREIGN KEY (user) REFERENCES users(id) ON DELETE CASCADE
            );'
    
            @db.execute 'CREATE TABLE IF NOT EXISTS pipes(
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            pipe TEXT,
                            title TEXT,
                            description TEXT,
                            user INTEGER,
                            preview TEXT,
                            public BOOLEAN DEFAULT 0, 
                            publicdate INTEGER DEFAULT 0,
                            date INTEGER DEFAULT CURRENT_TIMESTAMP,
                            FOREIGN KEY(user) REFERENCES users(id)
            );'

            @db.execute "CREATE TABLE IF NOT EXISTS likes(
                                user INTEGER,
                                pipe INTEGER,
                                date INTEGER DEFAULT CURRENT_TIMESTAMP,
                                FOREIGN KEY (user) REFERENCES users(id) ON DELETE CASCADE,
                                FOREIGN KEY (pipe) REFERENCES pipes(id) ON DELETE CASCADE,
                                UNIQUE(user, pipe)
                                );"
                                
            @db.execute "CREATE TABLE IF NOT EXISTS tags(
                                pipe INTEGER,
                                tag TEXT,
                                date INTEGER DEFAULT CURRENT_TIMESTAMP,
                                FOREIGN KEY (pipe) REFERENCES pipes(id) ON DELETE CASCADE,
                                UNIQUE(tag, pipe)
                                );"
                                
            @db.execute "CREATE TABLE IF NOT EXISTS permaCache(
                                key TEXT PRIMARY KEY,
                                value TEXT,
                                date INTEGER DEFAULT CURRENT_TIMESTAMP
                                );"
        rescue => error
            warn "Error creating database: #{error}"
        end

        begin
            @db.execute 'SELECT publicdate FROM pipes;'
        rescue => error
            @db.execute 'ALTER TABLE pipes ADD publicdate INTEGER DEFAULT 0;'
        end
        
        begin
            @db.execute 'SELECT public FROM pipes;'
        rescue => error
            @db.execute 'ALTER TABLE pipes ADD public BOOLEAN DEFAULT 0;'
        end

        if (mode == :file)
            @hookdb = SQLite3::Database.new "hooks.db"
        else
            @hookdb = SQLite3::Database.new ":memory:"
        end

        begin
            @hookdb.execute 'CREATE TABLE IF NOT EXISTS hooks(
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            content TEXT,
                            blockid TEXT,
                            date INTEGER DEFAULT CURRENT_TIMESTAMP
            );'
            @hookdb.execute 'CREATE INDEX IF NOT EXISTS hooks_blockid_idx ON hooks(blockid);'
        rescue => error
            warn "Error creating hook database: #{error}"
        end

        @db.execute 'PRAGMA journal_mode = WAL;'
        @db.execute 'PRAGMA busy_timeout = 5000;'
        @db.execute 'PRAGMA synchronous = NORMAL;'
        @db.execute 'PRAGMA cache_size = 1000000000;'
        @db.execute 'PRAGMA foreign_keys = true;'
        @db.execute 'PRAGMA temp_store = memory;'
        @db.execute 'ANALYZE;'
        @db.results_as_hash = true
        @hookdb.execute 'PRAGMA journal_mode = WAL;'
        @hookdb.execute 'PRAGMA busy_timeout = 5000;'
        @hookdb.execute 'PRAGMA synchronous = NORMAL;'
        @hookdb.execute 'PRAGMA cache_size = 1000000000;'
        @hookdb.execute 'PRAGMA foreign_keys = true;'
        @hookdb.execute 'PRAGMA temp_store = memory;'
        @hookdb.execute 'ANALYZE;'
        @hookdb.results_as_hash = true

        options = { namespace: "pipes_v1", serializer: JSON, protocol: :meta }
        @dc = Dalli::Client.new('localhost:11211', options)
    end

    def storePipe(id: nil, pipe:, user:, preview:)
        addUser(email: user)
        if (id && id != '')
            # Update existing pipe, but only if it is a pipe of the user
            @db.execute('UPDATE pipes SET pipe = ?, preview = ? WHERE user = ? and id = ?', [pipe, preview, self.getUserId(email: user), id])
            self.uncache(id: id)
            return id
        else
            @db.execute('INSERT INTO pipes(pipe, title, description, user, preview) VALUES(?, "unnamed", "", ?, ?)', [pipe, self.getUserId(email: user), preview])
            return @db.last_insert_row_id 
        end
    end

    def copyPipe(id:, user:)
        @db.execute('INSERT INTO pipes(pipe, title, description, user, preview) SELECT pipe, title, description, user, preview FROM pipes WHERE id = ? AND user = ? ', [id, self.getUserId(email: user)])
        return @db.last_insert_row_id 
    end

    def getPipe(id:)
        return @db.execute('SELECT *, pipes.pipe as pipe, group_concat(tag) AS tags FROM pipes LEFT JOIN tags ON (pipes.id = tags.pipe) WHERE id = ? GROUP BY pipes.id', [id])[0]
    end
    
    def getPublicPipe(id:)
        return @db.execute('SELECT * FROM pipes WHERE id = ? AND public = 1', [id])[0]
    end

    def getPipes(user:)
        begin
            return @db.execute('SELECT *, group_concat(tag) AS tags FROM pipes LEFT JOIN tags ON (pipes.id = tags.pipe) WHERE user = ? GROUP BY pipes.id', [self.getUserId(email: user)])
        rescue => e
            warn "error getting pipes: #{e}"
            return []
        end
    end

    def getPublicPipes(order: nil, tag: nil)
        begin
            orderSQL = case order
                when 'new' then 'ORDER BY pipes.publicdate DESC'
                when 'likes' then 'ORDER BY COUNT(likes.pipe) DESC'
                else ''
            end
            
            if tag.nil?
                return @db.execute('SELECT pipes.id as id, pipes.user as user, pipes.pipe as pipe, title, description, preview, public, publicdate, pipes.date as date, COUNT(DISTINCT likes.user) AS likes, GROUP_CONCAT(DISTINCT tag) as tags FROM pipes LEFT JOIN likes ON (pipes.id = likes.pipe) LEFT JOIN tags ON (pipes.id = tags.pipe) WHERE public = 1 GROUP BY pipes.id ' +  orderSQL)
            else
                return @db.execute('SELECT pipes.id as id, pipes.user as user, pipes.pipe as pipe, title, description, preview, public, publicdate, pipes.date as date, COUNT(DISTINCT likes.user) AS likes, GROUP_CONCAT(DISTINCT tag) as tags FROM pipes LEFT JOIN likes ON (pipes.id = likes.pipe) LEFT JOIN tags ON (pipes.id = tags.pipe) WHERE public = 1 AND tag = ? GROUP BY pipes.id ' +  orderSQL, tag)
            end
        rescue => e
            warn "error getting public pipes: #{e}"
            return []
        end
    end

    def addUser(email:)
        @db.execute('INSERT OR IGNORE INTO users(email) VALUES (?)', [email])
    end

    def deleteUser(email:)
        @db.execute('DELETE FROM users WHERE email = ?', [email])
    end

    def getUserId(email:)
        return @db.execute('SELECT id FROM users WHERE email = ?', [email])[0]['id']
    end

    def cache(key:, value:)
        @dc.set(key, value, 600)

        # The key we get has the pipe id and the parameter hash. To be able to delete the cache, we
        # need to extract the pipe id here and link it to the cache entry.
        id = key.to_s.scan(/\[\d+\]/)[0]
        if id
            cacheslots = @dc.get("#{id}CacheEntries") || ''
            @dc.set("#{id}CacheEntries", (cacheslots.empty? ? '' : cacheslots + ',') + key, 600)
        end
    end

    def getCache(key:)
        return @dc.get(key)
    end

    # Delete all cache entries for the given pipe id
    def uncache(id:)
        @dc.delete(id)
        
        cacheslots = @dc.get("#{id}CacheEntries")&.split(',')
        cacheslots.each{|x| @dc.delete(x) } if cacheslots
    end

    def setPipeTitle(id:, user:, title:)
        begin
            @db.execute('UPDATE pipes SET title = ? WHERE user = ? and id = ?', [Sanitize.fragment(title), self.getUserId(email: user), id])
            self.uncache(id: id)
            return true
        rescue => error
            warn "setPipeTitle: #{error}"
        end
        return false
    end

    def sharePipe(id:, user:)
        begin
            @db.execute('UPDATE pipes SET public = 1 WHERE user = ? and id = ?', [self.getUserId(email: user), id])
            return true
        rescue => error
            warn "sharePipe: #{error}"
        end
        return false
    end

    def setPipeDescription(id:, user:, description:)
        begin
            @db.execute('UPDATE pipes SET description = ? WHERE user = ? and id = ?', [Sanitize.fragment(description), self.getUserId(email: user), id])
            return true
        rescue => error
            warn "setPipeDescription: #{error}"
        end
        return false
    end

    
    
    def unsharePipe(id:, user:)
        begin
            @db.execute('UPDATE pipes SET public = 0 WHERE user = ? and id = ?', [self.getUserId(email: user), id])
            return true
        rescue => error
            warn "unsharePipe: #{error}"
        end
        return false
    end
    
    def deletePipe(id:, user:)
        begin
            @db.execute('DELETE FROM pipes WHERE user = ? and id = ?', [self.getUserId(email: user), id])
            return true
        rescue => error
            warn "deletePipe: #{error}"
        end
        return false
    end


    def storeHook(content:, blockid:)
        begin
            @hookdb.execute("INSERT INTO hooks(content, blockid) VALUES(?, ?)", [content, blockid])
            cleanHooks if rand(20) == 10
        rescue => error
            warn "store hook: #{error}"
        end
    end
    
    def getHooks(blockid:)
        begin
            return @hookdb.execute("SELECT * FROM hooks WHERE CAST(blockid AS TEXT) LIKE ?", [blockid])
        rescue => error
            warn "get hooks: #{error}"
        end
    end

    def cleanHooks()
        begin
            return @hookdb.execute("DELETE FROM hooks WHERE CAST(strftime('%s', date) AS INT) < ?", [(Time.now - 3600).to_i])
        rescue => error
            warn "clean hooks: #{error}"
        end
    end

    def changeMail(new:, old:)
        begin
            @db.execute("UPDATE users SET email = ? WHERE email LIKE ?", [new, old])
            return @db.changes == 1
        rescue => error
            warn "error changing users email: #{error}"
        end
        return false
    end

    def likePipe(user:, pipe:)
        begin
            return @db.execute("INSERT INTO likes(user, pipe) VALUES(?, ?)", [self.getUserId(email: user), pipe])
        rescue => error
            warn "like pipe: #{error}"
        end
    end
    
    def unlikePipe(user:, pipe:)
        begin
            return @db.execute("DELETE FROM likes WHERE user = ? AND  pipe = ?", [self.getUserId(email: user), pipe])
        rescue => error
            warn "unlike pipe: #{error}"
        end
    end
    
    def getLikedPipes(user:)
        begin
            return [] if user.nil?
            return @db.execute("SELECT pipe FROM likes WHERE user = ?", [self.getUserId(email: user)])
        rescue => error
            warn "get liked pipes: #{error}"
        end
    end

    def getLikes(user:)
        begin
            return @db.execute("SELECT COUNT(likes.pipe) from pipes LEFT JOIN likes ON (pipes.id = likes.pipe) WHERE pipes.user = ? AND likes.user != ?", [self.getUserId(email: user), self.getUserId(email: user)])[0].values.first
        rescue => error
            warn "get likes: #{error}"
        end
        return 0
    end

    def getTags()
        begin
            return @db.execute("SELECT DISTINCT(tag) as tag FROM tags;").map{|x| x['tag']}
        rescue => error
            warn "get tags: #{error}"
        end
    end

    def addTag(user:, pipe:, tag:)
        begin
            if self.getPipe(id: pipe)['user'] == self.getUserId(email: user)
                tag.split(',').each do |split_tag|
                    @db.execute("INSERT INTO tags(tag, pipe) VALUES(?, ?)", [Sanitize.fragment(split_tag).strip, pipe])
                end
                return true
            end
        rescue => error
            warn "addTag: #{error}"
        end
        return false
    end
    
    def removeTag(user:, pipe:, tag:)
        begin
            if self.getPipe(id: pipe)['user'] == self.getUserId(email: user)
                return @db.execute("DELETE FROM tags WHERE tag = ? AND pipe = ?", [Sanitize.fragment(tag), pipe])
            end
        rescue => error
            warn "removeTag: #{error}"
        end
    end

    def getset(key, value)
        rows = @db.execute("SELECT value FROM permaCache WHERE key = ?", [key])
        return rows[0]['value'] if rows && rows.size > 0
        @db.execute("INSERT INTO permaCache(key, value) VALUES(?, ?)", [key, value])
        return value
    end
    
end