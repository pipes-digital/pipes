require 'oxml'
require 'json'
require 'janeway'
require 'rss'

# This is what flows through the pipes. Store the data structure, save the original data type, and
# be able to output in target formats (XML, JSON, ?).
#
# Blocks then operate on this class, on the stored ruby hash. That way we can implement all possible
# operations without being limited by format specific helper libraries.
#
# It is important that the conversions are lossless, e.g. not losing namespaces, to produce
# valid RSS feeds etc after flowing through the pipe.

class Water
    # Remember what type the data had initially. That might become useful if we have blocks
    # that only work on some data types (e.g. not on CSV)
    attr_accessor :orig_format
    
    # The core, the real data. Might be the content of an RSS feed transformed into a hash structure
    attr_accessor :data

    # Take in data, like XML or JSON given as string(?), and transform them to a ruby hash structure
    # in @data and store their original format at @orig_format
    def absorb(input)
        begin
            input = input.to_s if input.kind_of?(RSS::Rss)
            self.data = OXML.parse(input, options = {
                strip_namespaces: false,
                delete_namespace_attributes:  false,
                advanced_typecasting: false,
                skip_soap_elements: false,
                symbolize_keys: false
            })
            self.orig_format = :xml
            return self
        rescue NoMethodError
            # input could not be parsed as xml
        rescue => e
            warn "unexpected error in absorbing xml"
            warn e
        end
        begin
            self.data = JSON.parse(input)
            self.orig_format = :json
        rescue => e
            warn "unexpected error in absorbing json"
            warn e
        end
        return self
    end

    # Return @data in the given format as string. Valid format values are :xml or :json. If none is
    # given use @orig_format for the output.
    def solidify(format = nil)
        format = self.orig_format if format.nil?
        if format == :xml
            return OXML.build(data)
        end
        if format == :json
            return JSON.generate(data)
        end
    end

    # Return a hash that contains the structure of @data, without the values.
    # Use this to set the input elements of blocks working with this data, to show on which node of
    # the data structure operations can be performed.
    def outline()
        paths = []
        Janeway.enum_for('$..*', data).each do |_bird, _parent, _index, path|
            paths << path
        end
        # paths are given in a normalized paths not suited for the frontend. Here we transform them
        # to regular json paths, and merge array access into one (-> [*])
        paths.map{|x| x.gsub(/\[[0-9]+\]/, '[*]')
                        .gsub("']['", '.')
                        .gsub("$['", '$.')
                        .gsub("'][*]", '[*]')
                        .gsub("[*]['", '[*].')
                        .delete_suffix("']")
                }.uniq
    end

end