require 'rss'
require_relative '../block.rb'
require_relative "../blocks/filterblock.rb"
require "test/unit"
 
class TestFilterBlock < Test::Unit::TestCase

    # A filter block can remove items by their title
    def test_blocking_items_by_title
        filterblock = Filterblock.new
        filterblock.options = {:userinputs => ['/First/i', true, 'title']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
            </channel>
        </rss>')
        assert_no_match(/<title>First<\/title>/, filterblock.process([test_feed]).to_s)
        assert_match(/<title>Second<\/title>/, filterblock.process([test_feed]).to_s)
    end

    # A filter block can keep items by their title, remove all other items
    def test_keeping_items_by_title
        filterblock = Filterblock.new
        filterblock.options = {:userinputs => ['/First/i', false, 'title']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
            </channel>
        </rss>')
        assert_match(/<title>First<\/title>/, filterblock.process([test_feed]).to_s)
        assert_no_match(/<title>Second<\/title>/, filterblock.process([test_feed]).to_s)
    end

    # A filter block can remove items by a string no matter the field it is in
    def test_blocking_items
        filterblock = Filterblock.new
        filterblock.options = {:userinputs => ['/First/i', true, 'all']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>DEF</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>HIJ</description></item>
            </channel>
        </rss>')
        assert_no_match(/<title>First<\/title>/, filterblock.process([test_feed]).to_s)
        assert_match(/<title>Second<\/title>/, filterblock.process([test_feed]).to_s)

        filterblock.options = {:userinputs => ['/DEF/i', true, 'all']}
        assert_no_match(/<description>DEF<\/description>/, filterblock.process([test_feed]).to_s)
    end
 
end