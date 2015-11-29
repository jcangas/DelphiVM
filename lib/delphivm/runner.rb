
require 'mini_portile' # force OCRA sees it !!

require 'nokogiri'
require 'zip'

require 'open3'
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
	  		["#{GEM_ROOT}/lib/dvm/**/*.thor", "#{Delphivm::PRJ_ROOT}/dvm/**/*.thor"]
		end
	end

	class Runner
		# remove some tasks not needed
		remove_task :install, :installed, :uninstall, :update

		# default version and banner methods outputs THOR, so redefine both

		def self.banner(task, all = false, subcommand = false)
			"#{Delphivm::EXE_NAME} " + task.formatted_usage(self, all, subcommand)
		end

		desc "version", "Show #{Delphivm::EXE_NAME} version"
		def version
			say "#{Delphivm::VERSION}"
		end
	end
end
