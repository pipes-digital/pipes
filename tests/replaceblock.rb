require 'rss'
require_relative '../block.rb'
require_relative "../blocks/replaceblock.rb"
require "test/unit"
 
class TestReplaceBlock < Test::Unit::TestCase

    # Capable of replacing a string
    def test_replace_item_title
        replaceblock = Replaceblock.new
        replaceblock.options = {:userinputs => ['/First/i', 'Last']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
            </channel>
        </rss>')
        assert_no_match(/<title>First<\/title>/, replaceblock.process([test_feed]).to_s)
        assert_match(/<title>Last<\/title>/, replaceblock.process([test_feed]).to_s)
    end

    # Capable of replacing a string, but does so only in the selected field
    def test_replace_respects_field
        replaceblock = Replaceblock.new
        replaceblock.options = {:userinputs => ['/Second/i', 'Last', 'title']}
        test_feed = RSS::Parser.parse('<rss version="2.0">
                <channel>
                <title>title</title><link></link><description>Three items.</description>
                <item><title>First</title><link>https://www.example.com/</link><pubDate>Sun, 18 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Third</title><link>https://www.example.com/</link><pubDate>Tue, 20 Sep 2022 04:37:58 +0000</pubDate><description>ABC</description></item>
                <item><title>Second</title><link>https://www.example.com/</link><pubDate>Mon, 19 Sep 2022 04:37:58 +0000</pubDate><description>Second</description></item>
            </channel>
        </rss>')
        assert_no_match(/<title>Second<\/title>/, replaceblock.process([test_feed]).to_s)
        assert_match(/<title>Last<\/title>/, replaceblock.process([test_feed]).to_s)
        assert_match(/<description>Second<\/description>/, replaceblock.process([test_feed]).to_s)
    end

    # Work with &#0; in title
    def test_replace_works_with_malformed_title
        replaceblock = Replaceblock.new
        replaceblock.options = {:userinputs => ['/Bad title.*/i', 'New title', 'title']}

        test_feed = Class.new do
            def run
                RSS::Parser.parse('<?xml version="1.0" encoding="UTF-8" ?>
            <rss version="2.0">
            <channel>
              <title>Example</title>
              <link>https://example.com/</link>
              <description>Example feed</description>
              <item>
                <title>Bad title &#0;&#0;&#0;&#0;&#0;</title>
                <link>https://example.com/8325262</link>
                <description>An item with a bad title</description>
              </item>
              <item>
                <title>Good title</title>
                <link>https://example.com/4325262</link>
                <description>An item with a good title</description>
              </item>
            </channel>
            </rss>')
            end
        end
        test_feed = test_feed.new
        
        replaceblock.inputs << test_feed
        output = replaceblock.run.to_s

        
        assert_no_match(/<title>Bad title<\/title>/, output)
        assert_match(/<title>Good title<\/title>/, output)
        assert_match(/<title>New title<\/title>/, output)
    end

end