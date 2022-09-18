require_relative '../block.rb'
require_relative "../blocks/sortblock.rb"
require "test/unit"
 
class TestSortBlock < Test::Unit::TestCase
 
    def test_empty_feed
        sortblock = Sortblock.new
        sortblock.options = {:userinputs => ['updated', 'desc']}
        empty_feed = '<rss version="2.0"><channel><title>An empty feed</title><link></link><description>No items.</description></channel></rss>'
        assert_equal('<rss version="2.0"><channel><title>Nothing to sort</title><link></link><description>The input feed contained no items.</description></channel></rss>', sortblock.process([empty_feed]))
    end

    
    def test_newest_first
        sortblock = Sortblock.new
        sortblock.options = {:userinputs => ['published', 'desc']}
        test_feed = '<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
            </channel>
        </rss>'
        assert_equal(['<pubDate>Tue, 20 Sep 2022 04:37:58 -0000</pubDate>', '<pubDate>Mon, 19 Sep 2022 04:37:58 -0000</pubDate>', '<pubDate>Sun, 18 Sep 2022 04:37:58 -0000</pubDate>'], sortblock.process([test_feed]).scan(/<pubDate>.*<\/pubDate>/).last(3))
    end

    def test_oldest_first
        sortblock = Sortblock.new
        sortblock.options = {:userinputs => ['published', 'asc']}
        test_feed = '<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
            </channel>
        </rss>'
        assert_equal(['<pubDate>Sun, 18 Sep 2022 04:37:58 -0000</pubDate>', '<pubDate>Mon, 19 Sep 2022 04:37:58 -0000</pubDate>', '<pubDate>Tue, 20 Sep 2022 04:37:58 -0000</pubDate>'], sortblock.process([test_feed]).scan(/<pubDate>.*<\/pubDate>/).last(3))
    end
 
end