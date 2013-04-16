require 'thor/runner'

class Delphivm
	EXE_NAME = File.basename($0, '.rb')
	
	PATH_TO_VENDOR = ROOT + 'vendor'
	PATH_TO_VENDOR_CACHE = PATH_TO_VENDOR + 'cache'
	PATH_TO_VENDOR_IMPORTS = PATH_TO_VENDOR + 'imports'
	DVM_IMPORTS_FILE = PATH_TO_VENDOR + 'imports.dvm'

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
