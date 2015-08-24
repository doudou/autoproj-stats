module Autoproj
    module Stats
        # Statistic generator for git-based packages
        class Git
            attr_reader :sloc_counter
            attr_reader :sanitizer
            def initialize(sloc_counter: SLOCCounter.new, sanitizer: Sanitizer.new)
                @sloc_counter = sloc_counter
                @sanitizer = sanitizer
            end

            def call(pkg)
                pkg.progress_start "processing %s", done_message: "processed %s" do
                    importer = pkg.importer
                    entries = importer.run_git(pkg, 'ls-tree', '-r', 'HEAD', encoding: 'UTF-8')

                    progress_counter = 0
                    entries.inject(PackageStats.new) do |aggregate, line|
                        mode, type, sha, path = line.split(/\s+/)
                        if file_counter = sloc_counter.find_counter_for_path(path)
                            aggregate += process_file(pkg, path, sloc: file_counter)
                        else
                            pkg.warn "%s: no SLOC count counter available for #{path}"
                        end
                        progress_counter += 1
                        pkg.progress "processing %s (#{progress_counter}/#{entries.size})"
                        aggregate
                    end
                end
            end

            def process_file(pkg, path, sloc: proc { true })
                blamed = pkg.importer.run_git(pkg, 'blame', '-w', '-C', '-M', '--minimal', 'HEAD', '--', path, encoding: 'UTF-8')

                authors = Hash.new(0)
                copyrights = Hash.new(0)

                line_matcher = Regexp.new(/^\^?[0-9a-f]+.*\((.*) (\d{4})-(\d{2})-(\d{2}).*\d+\) (.*)$/)
                blamed.each do |line|
                    line = line.encode('UTF-8', invalid: :replace, undef: :replace)
                    if m = line_matcher.match(line)
                        _, name, y, m, d, code = *m
                        code = code.strip
                        next if code.empty? || !sloc.(code)

                        name = sanitizer.sanitize_author_name(name.strip)
                        copyright = sanitizer.compute_copyright_of(
                            name, Date.new(y.to_i, m.to_i, d.to_i))
                        authors[name] += 1
                        copyrights[copyright] += 1
                    else
                        raise "cannot match #{line}"
                    end
                end

                sloc = authors.values.inject(0, &:+)
                PackageStats.new(sloc, authors, copyrights)
            end
        end
    end
end

