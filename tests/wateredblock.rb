require_relative '../water.rb'
require_relative '../block.rb'
require_relative '../blocks/filterblock.rb'

require "test/unit"
require 'rss'
 
class TestWateredBlock < Test::Unit::TestCase

    # A watered block can take the output of a regular block and work with that
    def test_absorbing_rss_block
        filterblock = Filterblock.new
        filterblock.options = {:userinputs => ['/First/i', true, 'title']}
        test_feed = Class.new do
            def run
                RSS::Parser.parse('<rss version="2.0">
                    <channel>
                    <title>title</title><link></link><description>Three items.</description>
                    <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                    <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                    <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                </channel>
                </rss>')
            end
        end
        test_feed = test_feed.new
        
        filterblock.inputs << test_feed

        wateredfilterblock = WateredFilterblock.new
        wateredfilterblock.options = {:userinputs => ['$.rss.channel.item', 'title', 'Second', 'contains']}
        wateredfilterblock.inputs << filterblock

        output = wateredfilterblock.run.solidify
        
        assert_no_match(/<title>First<\/title>/, output)
        assert_no_match(/<title>Second<\/title>/, output)
        assert_match(/<title>Third<\/title>/, output)
        
    end

 
end