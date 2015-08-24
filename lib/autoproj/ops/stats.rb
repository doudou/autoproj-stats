require 'autoproj/stats'

module Autoproj
    module Ops
        # Computes per-package statistics
        class Stats
            attr_reader :sanitizer

            def initialize(sanitizer: Autoproj::Stats::Sanitizer.new)
                @sanitizer = sanitizer
            end

            def process(packages, parallel: 1)
                executor = Concurrent::FixedThreadPool.new(parallel, max_length: 0)
                result = Hash.new

                futures = packages.map do |pkg|
                    [pkg, Concurrent::Future.execute(executor: executor) { compute_package_stats(pkg) }]
                end
                futures.inject(Hash.new) do |h, (pkg, future)|
                    if stats = future.value
                        h[pkg] = stats
                    elsif future.reason.kind_of?(Exception)
                        raise future.reason
                    else
                        pkg.error "%s: failed, #{future.reason}"
                    end
                    h
                end

            ensure
                executor.shutdown
                executor.wait_for_termination
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
