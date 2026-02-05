require_relative '../block.rb'
require_relative "../blocks/sortblock.rb"
require "test/unit"
 
class TestSortBlock < Test::Unit::TestCase

    # Returns a helpful error feed if the input feed has no items
    def test_empty_feed
        sortblock = Sortblock.new
        sortblock.options = {:userinputs => ['updated', 'desc']}
        empty_feed = RSS::Parser.parse('<rss version="2.0"><channel><title>An empty feed</title><link></link><description>No items.</description></channel></rss>')
        assert_match(/<title>Nothing to sort<\/title>/, sortblock.process([empty_feed]).to_s)
    end

    # Properly sort by date so that the newest item comes first, when desc is selected
    def test_newest_first
        sortblock = Sortblock.new
        sortblock.options = {:userinputs => ['published', 'desc']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
            </channel>
        </rss>')
        assert_equal(['<pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate>', '<pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate>', '<pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate>'], sortblock.process([test_feed]).to_s.scan(/<pubDate>.*<\/pubDate>/).last(3))
    end

    # Properly sort by date so that the oldest item comes first, when asc is selected
    def test_oldest_first
        sortblock = Sortblock.new
        sortblock.options = {:userinputs => ['published', 'asc']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
            </channel>
        </rss>')
        assert_equal(['<pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate>', '<pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate>', '<pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate>'], sortblock.process([test_feed]).to_s.scan(/<pubDate>.*<\/pubDate>/).last(3))
    end
 
end