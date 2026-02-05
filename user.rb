class User
    MAX_PIPES_LIMIT = ENV['PIPES_MAX_USER_PIPES'] ? ENV['PIPES_MAX_USER_PIPES'].to_i : 1000

    attr_accessor :email
    attr_accessor :plan

    def initialize(email:)
        self.email = email
        self.plan = Database.instance.getPlan(user: email)
    end

    def hasFreeStorage()
        pipes = Database.instance.getPipes(user: email)
        pipes.size < MAX_PIPES_LIMIT
    end

    # Fetch the json code for all pipes the user owns and put them into a single string. This will also make sure all the information I don't
    # want to have leaked, like the pipe id, are not included in the output
    def export()
        rows = Database.instance.getPipes(user: self.email)
        output = ""
        rows.each do |row|
            pipe = Database.instance.getPipe(id: row['id'])['pipe']
            output += pipe
            output += "\n"
            
        end
        return output
    end

    def deleteUser!()
        rows = Database.instance.getPipes(user: self.email)
        rows.each do |row|
            Database.instance.deletePipe(user: self.email, id: row['id'])
        end
        Database.instance.deleteUser(email: self.email)
    end
end