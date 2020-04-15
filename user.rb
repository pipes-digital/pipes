class User
    attr_accessor :email
    attr_accessor :plan

    def initialize(email:)
        self.email = email
        self.plan = Database.instance.getPlan(user: email)
    end

    def hasFreeStorage()
        pipes = Database.instance.getPipes(user: email)
        pipes.size < 1000
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
end