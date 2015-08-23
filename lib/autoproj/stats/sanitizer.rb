module Autoproj
    module Stats
        # Class passed to the stats generators to sanitize names and compute
        # copyright
        class Sanitizer
            attr_reader :aliases
            def initialize(aliases: Hash.new)
                @aliases = aliases
            end

            def load(path)
                config = YAML.load(File.read(path))
                @aliases = config['aliases']
            end

            def sanitize_author_name(name)
                aliases[name] || name
            end

            def compute_copyright_of(author_name, date)
                "unknown"
            end
        end
    end
end


