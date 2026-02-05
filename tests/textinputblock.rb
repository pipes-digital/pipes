require 'rss'
require_relative '../block.rb'
require_relative '../database.rb'
require_relative "../blocks/textinputblock.rb"
require "test/unit"
 
class TestTextInputBlock < Test::Unit::TestCase

    def setup
        Database.instance.testmode
    end

    # The textinput block returns its default by default
    def test_textinputdefault
        block = Textinputblock.new
        block.options = {:userinputs => ['url', 'https://www.onli-blogging.de']}
        assert_equal('https://www.onli-blogging.de', block.process([]).to_s)
    end

end