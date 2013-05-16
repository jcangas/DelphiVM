require 'delphivm/version'
require 'delphivm/ide_services'
require 'delphivm/dsl'

require 'thor/runner'

class Delphivm	
	class Runner
		# remove some tasks not needed
		remove_task :install, :installed, :uninstall, :update

		# default version and banner outputs THOR, so redefine it
		def self.banner(task, all = false, subcommand = false)
			"#{Delphivm::EXE_NAME} " + task.formatted_usage(self, all, subcommand)
		end    

		desc "version", "Show #{Delphivm::EXE_NAME} version"
		def version
			say "#{Delphivm::VERSION}"
		end
	end
end
