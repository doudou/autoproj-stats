require 'autoproj'
require 'autoproj/cli/inspection_tool'
require 'autoproj/ops/stats'
require 'concurrent'

require 'tty-table'

module Autoproj
    module CLI
        class Stats < InspectionTool
            def run(user_selection, options = Hash.new)
                initialize_and_load
                source_packages, * =
                    finalize_setup(user_selection,
                                   ignore_non_imported_packages: true)
                source_packages = source_packages.map { |pkg_name| ws.manifest.find_autobuild_package(pkg_name) }

                config = YAML.load(File.read(options[:config]))
                excluded = (config['exclude'] || Set.new).to_set
                sanitizer = Autoproj::Stats::Sanitizer.new
                if options[:config]
                    sanitizer.load(options[:config])
                end

                total_sloc = 0
                overall_per_author = Hash.new
                overall_per_copyright = Hash.new
                overall_copyright_per_license = Hash.new

                ops = Ops::Stats.new(sanitizer: sanitizer)
                stats = ops.process(source_packages, parallel: options[:parallel])
                per_package_table = TTY::Table.new
                stats.each do |pkg, pkg_stats|
                    next if excluded.include?(pkg.name)
                    row_count = [1, pkg_stats.authors.size, pkg_stats.copyright.size].max

                    # Compute per-package info
                    sloc = pkg_stats.sloc
                    author_info    = line_count_summary(pkg_stats.authors, sloc)
                    copyright_info = line_count_summary(pkg_stats.copyright, sloc)
                    license = sanitizer.license_of(pkg)

                    # Compute aggregated info
                    total_sloc += sloc
                    overall_per_author.merge!(pkg_stats.authors) { |_, v1, v2| v1 + v2 }
                    overall_per_copyright.merge!(pkg_stats.copyright) { |_, v1, v2| v1 + v2 }
                    copyrights_for_this_license =
                        (overall_copyright_per_license[license || "Unknown"] ||= Hash.new)
                    copyrights_for_this_license.merge!(pkg_stats.copyright) { |_, v1, v2| v1 + v2 }

                    Array.new(row_count).zip([pkg.name], [sloc], [license], *author_info, *copyright_info) do |line|
                        per_package_table << line[1..-1].map { |v| v || '' }
                    end
                end

                no_license = stats.find_all do |pkg, pkg_stats|
                    !sanitizer.license_of(pkg)
                end

                copyright_per_license_table = TTY::Table.new
                overall_copyright_per_license.sort_by(&:first).each do |license_name, copyrights|
                    first_col = Array.new(copyrights.size)
                    first_col[0] = license_name
                    copyright_info = line_count_summary(copyrights, total_sloc)
                    first_col.zip(*copyright_info) do |line|
                        copyright_per_license_table << line.map { |v| v || "" }
                    end
                end

                no_stats = (source_packages.to_set - stats.keys.to_set)
                puts "could not compute stats for #{no_stats.size} packages: #{no_stats.map(&:name).sort.join(", ")}"
                puts "#{no_license.size} packages without known license: #{no_license.map { |pkg, _| pkg.name }.sort.join(", ")}"
                puts "#{stats.size} Packages"
                puts "#{total_sloc} SLOC counted"
                puts "#{overall_per_author.size} unique authors"

                begin
                    io = if path = options[:save]
                             File.open(path, 'w')
                         else
                             STDOUT
                         end

                    io.puts "== Overall stats per author (sorted by contribution)"
                    author_names, *author_info = line_count_summary(overall_per_author, total_sloc)
                    io.puts TTY::Table.new(author_names.zip(*author_info)).render(:ascii)
                    io.puts
                    io.puts "== Overall stats per author (sorted alphabetically)"
                    author_names, *author_info = line_count_summary(overall_per_author, total_sloc, &:first)
                    io.puts TTY::Table.new(author_names.zip(*author_info)).render(:ascii)
                    io.puts
                    io.puts "== Overall stats per copyright"
                    copyright_names, *copyright_info = line_count_summary(overall_per_copyright, total_sloc)
                    io.puts TTY::Table.new(copyright_names.zip(*copyright_info)).render(:ascii)
                    io.puts
                    io.puts "== Breakdown of copyright per license"
                    io.puts copyright_per_license_table.render(:ascii)
                    io.puts
                    io.puts "== Per-package stats"
                    io.puts per_package_table.render(:ascii)
                ensure
                    if io && io != STDOUT
                        io.close
                    end
                end
            end

            def line_count_summary(count_per_category, sloc, reverse: true, &block)
                ordered =
                    if block_given?
                        count_per_category.sort_by(&block)
                    else
                        count_per_category.sort_by { |_, count| count }
                    end
                ordered = ordered.reverse if reverse
                names  = ordered.map(&:first)
                counts = ordered.map(&:last)
                ratios = count_to_ratios(counts, sloc)
                return names, counts, ratios
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
