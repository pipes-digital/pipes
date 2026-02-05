require_relative '../water.rb'
require_relative '../database.rb'
require_relative '../downloader.rb'

require "test/unit"
require 'rss'
 
class TestWater < Test::Unit::TestCase

    def setup
        Database.instance.testmode
        @rss = Downloader.new.get('https://www.onli-blogging.de/feeds/index.rss2')
        @atom = Downloader.new.get('https://www.onli-blogging.de/feeds/index.atom2')
        @xml = File.open(__dir__ + '/example.xml').read
        @json = File.open(__dir__ + '/example.json').read
    end

    # Can ingest an rss feed
    def test_absorbing_rss
        water = Water.new.absorb(@rss)
        assert_not_empty(water.data)
    end

    # Can output a prior ingested rss feed
    def test_solidifying_rss
        water = Water.new.absorb(@rss)
        recreated_rss = water.solidify
        parsed_orig = RSS::Parser.parse(@rss)
        parsed_recreated = RSS::Parser.parse(recreated_rss)
        assert_equal(parsed_orig.items.length, parsed_recreated.items.length)
        assert_equal(parsed_orig.channel.title, parsed_orig.channel.title)
    end

    # Can ingest an atom feed
    def test_absorbing_atom
        water = Water.new.absorb(@atom)
        assert_not_empty(water.data)
    end

    # Can output a prior ingested atom feed
    def test_solidifying_atom
        water = Water.new.absorb(@atom)
        recreated_atom = water.solidify
        parsed_orig = RSS::Parser.parse(@atom)
        parsed_recreated = RSS::Parser.parse(recreated_atom)
        assert_equal(parsed_orig.items.length, parsed_recreated.items.length)
        assert_equal(parsed_orig.title, parsed_orig.title)
    end

    # Can ingest regular xml
    def test_absorbing_xml
        water = Water.new.absorb(@xml)
        assert_not_empty(water.data)
    end

    # Can output regular xml
    def test_solidifying_xml
        water = Water.new.absorb(@xml)
        recreated_xml = water.solidify
        assert_match(/book id="bk112"/, recreated_xml)
    end

    # Can output prior ingested xml as json
    def test_solidifying_xml_as_json
        water = Water.new.absorb(@xml)
        recreated_xml = water.solidify(:json)
        assert_match(/"@id":"bk112"/, recreated_xml)
    end

    # Can ingest json
    def test_absorbing_json
        water = Water.new.absorb(@json)
        assert_not_empty(water.data)
    end

    # The outline of an ingested RSS feed looks correct, it has some key elements in it
    def test_outline
        water = Water.new.absorb(@rss)
        assert(water.outline.include?("$.rss"))
        assert(water.outline.include?("$.rss.channel.item[*].guid.@is_perma_link"))
        assert(water.outline.include?("$.rss.channel.item[*]"))
    end
 
end