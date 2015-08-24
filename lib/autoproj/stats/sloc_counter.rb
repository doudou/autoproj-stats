module Autoproj
    module Stats
        class SLOCCounter
            def find_counter_for_path(path)
                case path
                when /\.rb$/, /\.orogen$/
                    lambda { |line| line !~ /^(?:#|end)$/ }
                when /\.py$/
                    lambda { |line| line !~ /^#/ }
                when /\.(?:[ch]pp|cc?|hh?)$/
                    lambda { |line| line !~ /^(?:[{}]+|\/\/)$/ }
                when /CMakeLists.txt/, /\.cmake$/
                    lambda { |line| line !~ /^#/ }
                when /\.sdf$/
                    lambda { |line| true }
                end
            end
        end
    end
end

