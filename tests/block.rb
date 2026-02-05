require 'rss'
require_relative '../block.rb'
require_relative '../database.rb'
require_relative "../blocks/textinputblock.rb"
require_relative "../blocks/filterblock.rb"
require "test/unit"
 
class TestBlock < Test::Unit::TestCase

    def setup
        Database.instance.testmode
    end

    # The textinput block returns a string on timeout
    def test_textinputtimeout
        block = Textinputblock.new
        block.options = {:userinputs => ['url', 'https://www.onli-blogging.de']}
        pipe = Class.new do
            def user
                nil
            end
            def id
                'testid'
            end
            def starttime
                Time.now - 60
            end
        end
        block.pipe = pipe.new
        assert_kind_of(String, block.run)
    end
    
    # Other blocks returns a RSS object on timeout
    def test_filtertimeout
        block = Filterblock.new
        block.options = {:userinputs => ['/First/i', true, 'title']}
        pipe = Class.new do
            def user
                nil
            end
            def id
                'testid'
            end
            def starttime
                Time.now - 60
            end
        end
        block.pipe = pipe.new
        assert_kind_of(RSS::Rss, block.run)
    end

end