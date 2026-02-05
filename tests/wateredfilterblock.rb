require_relative '../block.rb'
require_relative '../water.rb'
require_relative "../blocks/filterblock.rb"
require "test/unit"
 
class TestWateredFilterBlock < Test::Unit::TestCase

    # Can block items that contain a specific field with a keyword
    def test_blocking_items_contain
        filterblock = WateredFilterblock.new
        filterblock.options = {:userinputs => ['$.catalog.book', 'title', 'XML', 'contains']}
        water = Water.new
        water.absorb(File.open(__dir__ + '/example.xml').read)
        assert_no_match(/<book id="bk101">/, filterblock.process([water]).solidify)
        assert_no_match(/<book id="bk111">/, filterblock.process([water]).solidify)
    end

    # Can block items that do not contain a specific field with a keyword
    def test_blocking_items_missing
        filterblock = WateredFilterblock.new
        filterblock.options = {:userinputs => ['$.catalog.book', 'title', 'XML', 'misses']}
        water = Water.new
        water.absorb(File.open(__dir__ + '/example.xml').read)
        assert_match(/<book id="bk101">/, filterblock.process([water]).solidify)
        assert_match(/<book id="bk111">/, filterblock.process([water]).solidify)
    end

    # Can block items that contain a speficic field that matches a given regular expression
    def test_blocking_items_regexp
        filterblock = WateredFilterblock.new
        filterblock.options = {:userinputs => ['$.catalog.book', 'title', '^XML.*', 'regexp']}
        water = Water.new
        water.absorb(File.open(__dir__ + '/example.xml').read)
        assert_no_match(/<book id="bk101">/, filterblock.process([water]).solidify) # Remove the book with leading XML in the title
        assert_match(/<book id="bk111">/, filterblock.process([water]).solidify) # Keep the book with XML later in the title
    end

    # Can remove items directly, withotu checking a field or a keyword
    def test_blocking_items_by_direct_path
        filterblock = WateredFilterblock.new
        filterblock.options = {:userinputs => ['$.catalog.book[*].title', '', 'XML', 'contains']}
        water = Water.new
        water.absorb(File.open(__dir__ + '/example.xml').read)
        assert_match(/<book id="bk101">/, filterblock.process([water]).solidify)  # The XML book itself is still here
        assert_no_match(/<title>XML Developer's Guide/, filterblock.process([water]).solidify) # But without the title
    end

    # Can remove items by the value of an array item of a specific field
    def test_blocking_array_by_item
        filterblock = WateredFilterblock.new
        filterblock.options = {:userinputs => ['$.book', 'category', 'a', 'contains']}
        water = Water.new
        water.absorb(
            {book:
                [ {title: 'test1', category: ['a', 'b' ]}, {title: 'test2', category: ['c', 'd' ]} ]
            }.to_json
        )
        assert_no_match(/test1/, filterblock.process([water]).solidify)
        assert_match(/test2/, filterblock.process([water]).solidify)
    end

    # Can also block items of RSS fields (as a special case of the json block tests above)
    def test_blocking_array_by_rss_item
        filterblock = WateredFilterblock.new
        filterblock.options = {:userinputs => ['$.rss.channel.item', 'category', 'jahresrückblick', 'contains']}
        water = Water.new
        water.absorb(File.open(__dir__ + '/example.rss').read)
        assert_no_match(/<title>Dinge, die ich 2025 nicht gekauft habe<\/title>/, filterblock.process([water]).solidify)
        assert_match(/Linksammlung 2\/2026/, filterblock.process([water]).solidify)
    end
 
end