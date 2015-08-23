require 'autoproj'
require 'autoproj/cli/inspection_tool'
require 'autoproj/ops/stats'

require 'tty-table'

module Autoproj
    module CLI
        class Stats < InspectionTool
            def run(user_selection, options = Hash.new)
                initialize_and_load
                source_packages, * =
                    finalize_setup(user_selection,
                                   recursive: false,
                                   ignore_non_imported_packages: true)
                source_packages = source_packages.map { |pkg_name| ws.manifest.find_autobuild_package(pkg_name) }


                sanitizer = Autoproj::Stats::Sanitizer.new
                if options[:config]
                    sanitizer.load(options[:config])
                end

                ops = Ops::Stats.new(sanitizer: sanitizer)
                stats = ops.process(source_packages)
                table = TTY::Table.new #(header: %w{name sloc authors copyright})
                stats.each do |pkg, pkg_stats|
                    row_count = [1, pkg_stats.authors.size, pkg_stats.copyright.size].max

                    sloc = pkg_stats.sloc
                    authors = pkg_stats.authors.sort_by { |_, count| count }.reverse
                    author_names  = authors.map(&:first)
                    author_counts = count_to_ratios(authors.map(&:last), sloc)
                    copyright_counts = count_to_ratios(pkg_stats.copyright.values, sloc)
                    Array.new(row_count).zip([pkg.name], [sloc], author_names, author_counts, pkg_stats.copyright.keys, copyright_counts) do |line|
                            table << line[1..-1].map { |v| v || '' }
                        end
                end
                puts table.render(:ascii)
            end

            def count_to_ratios(counts, total)
                counts.map do |v|
                    ratio = (Float(v) / total)
                    if ratio < 0.01
                        "< 1%"
                    else
                        "#{Integer(ratio * 100)}%"
                    end
                end
            end
        end
    end
end
