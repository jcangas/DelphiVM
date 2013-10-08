
require 'nokogiri'
require 'zip/zip'

require 'open3'
require 'win32/registry.rb'
require 'open-uri'
require 'net/http'
require 'ruby-progressbar'
require 'build_target'

require 'delphivm/version'
require 'delphivm/ide_services'
require 'delphivm/dsl'

require 'thor/runner'

class Delphivm	
	module Util #:nodoc:
	    # redefine Thor to search tasks only for this app
	    def self.globs_for(path)
	      ["#{GEM_ROOT}/lib/dvm/**/*.thor", "#{Delphivm::ROOT}/dvm/**/*.thor"]
	 	end
	end
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
