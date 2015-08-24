require 'autoproj/cli/stats'

class Autoproj::CLI::Main
    desc 'stats [PKG]', 'compute ownership information about the given package(s)'
    option 'config', desc: 'configuration file that specifies name mappings and copyright info'
    option 'parallel', desc: 'compute stats with that many parallel processes',
        type: :numeric, default: 1
    option 'save', desc: 'save in the provided file instead of outputting on STDOUT'
    def stats(*packages)
        run_autoproj_cli(:stats, :Stats, Hash[], *Array(packages))
    end
end

