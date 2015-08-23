require 'autoproj/cli/stats'

class Autoproj::CLI::Main
    desc 'stats [PKG]', 'compute ownership information about the given package(s)'
    option 'config', desc: 'configuration file that specifies name mappings and copyright info'
    def stats(*packages)
        run_autoproj_cli(:stats, :Stats, Hash[], *Array(packages))
    end
end

