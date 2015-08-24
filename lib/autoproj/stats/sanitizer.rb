module Autoproj
    module Stats
        # Class passed to the stats generators to sanitize names and compute
        # copyright
        class Sanitizer
            attr_reader :aliases
            attr_reader :simple_copyrights
            attr_reader :timeline_affiliations
            attr_reader :licenses

            def initialize(aliases: Hash.new)
                @simple_copyrights = Hash.new
                @timeline_affiliations = Hash.new
                @aliases = aliases
            end

            def load(path)
                config = YAML.load(File.read(path))
                @aliases = config['aliases']
                @licenses = config['licenses'] || Hash.new
                if affiliations = config['affiliations']
                    affiliations.each do |name, entry|
                        if entry.respond_to?(:to_str)
                            simple_copyrights[name] = entry
                        else
                            timeline_affiliations[name] = entry.sort_by(&:last)
                        end
                    end
                end
            end

            def license_of(pkg)
                licenses[pkg.name]
            end

            def sanitize_author_name(name)
                aliases[name] || name
            end

            def compute_copyright_of(author_name, date)
                if affiliation = simple_copyrights[author_name]
                    affiliation
                elsif timeline = timeline_affiliations[author_name]
                    timeline.inject("Unknown (#{author_name})") do |aff, (new_aff, start_date)|
                        if date < start_date
                            return aff
                        else
                            new_aff
                        end
                    end
                else
                    "Unknown (#{author_name})"
                end
            end
        end
    end
end


