require 'autoproj/stats'

module Autoproj
    module Ops
        # Computes per-package statistics
        class Stats
            attr_reader :sanitizer

            def initialize(sanitizer: Autoproj::Stats::Sanitizer.new)
                @sanitizer = sanitizer
            end

            def process(packages)
                packages.inject(Hash.new) do |h, pkg|
                    if stats = compute_package_stats(pkg)
                        h[pkg] = stats
                    end
                    h
                end
            end

            def compute_package_stats(pkg)
                if pkg.importer
                    if stats_generator = find_generator_for_importer(pkg.importer)
                        stats_generator.(pkg)
                    else
                        Autoproj.warn "no stats generator for #{pkg.name} (#{pkg.importer.class})"
                    end
                else
                    Autoproj.warn "no importer for #{pkg.name}"
                end
            end

            def find_generator_for_importer(importer)
                if importer.class == Autobuild::Git
                    return Autoproj::Stats::Git.new(sanitizer: sanitizer)
                end
            end
        end
    end
end
