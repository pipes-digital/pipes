require 'rss'
require_relative '../block.rb'
require_relative '../water.rb'
require_relative "../blocks/replaceblock.rb"
require "test/unit"
 
class TestWateredReplaceBlock < Test::Unit::TestCase

    # Can replace text
    def test_replace_item_title
        replaceblock = WateredReplaceblock.new
        replaceblock.options = {:userinputs => ['/First/i', 'Last']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
            </channel>
        </rss>')
        water = Water.new
        water.absorb(test_feed.to_s)
        assert_no_match(/<title>First<\/title>/, replaceblock.process([water]).solidify)
        assert_match(/<title>Last<\/title>/, replaceblock.process([water]).solidify)
    end

    # Can replace text, but does so only in the specified field
    def test_replace_respects_field
        replaceblock = WateredReplaceblock.new
        replaceblock.options = {:userinputs => ['/Second/i', 'Last', '$.rss.channel.item[*].title']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>Second</description></item>
            </channel>
        </rss>')
        water = Water.new
        water.absorb(test_feed.to_s)
        assert_no_match(/<title>Second<\/title>/, replaceblock.process([water]).solidify)
        assert_match(/<title>Last<\/title>/, replaceblock.process([water]).solidify)
        assert_match(/<description>Second<\/description>/, replaceblock.process([water]).solidify)
    end

end