module Autoproj
    module Stats
        class PackageStats
            attr_reader :sloc
            attr_reader :authors
            attr_reader :copyright
            def initialize(sloc = 0, authors = Hash.new, copyright = Hash.new)
                @sloc, @authors, @copyright = sloc, authors, copyright
            end

            def +(other)
                PackageStats.new(
                    sloc + other.sloc,
                    authors.merge(other.authors) { |_, v1, v2| v1 + v2 },
                    copyright.merge(other.copyright) { |_, v1, v2| v1 + v2 })
            end
        end
    end
end

