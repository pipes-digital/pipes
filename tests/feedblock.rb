require_relative '../block.rb'
require_relative '../downloader.rb'
require_relative '../database.rb'
require_relative "../blocks/feedblock.rb"
require "test/unit"
 
class TestFeedBlock < Test::Unit::TestCase

    def setup
        Database.instance.testmode
    end
 
    def test_legacyuserinput
        feedblock = Feedblock.new
        feedblock.options = {:userinput => 'https://www.onli-blogging.de'}
        assert_match(/<title>onli blogging<\/title>/, feedblock.process([]))
    end

    
    def test_regular_feed
        feedblock = Feedblock.new
        feedblock.options = {:userinputs => ['https://www.onli-blogging.de']}
        assert_match(/<title>onli blogging<\/title>/, feedblock.process([]))
    end
 
end