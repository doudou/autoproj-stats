module Autoproj
    module Stats
        class SLOCCounter
            def find_counter_for_path(path)
                case File.extname(path)
                when ".rb"
                    lambda { |line| line !~ /^\s*(?:#|end\s*$)/ }
                end
            end
        end
    end
end

