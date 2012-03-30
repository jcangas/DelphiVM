#!/usr/bin/env ruby

require 'thor'

Delphivm = Thor

class Delphivm
  ROOT = Pathname.getwd
end

require 'open3'
require 'zip/zip'
require 'win32/registry.rb'

require 'version_info'
require 'open-uri'
require 'progressbar'

require 'extensions'
require 'delphivm/version'
require 'delphivm/ide_services'
require 'delphivm/dsl'

require 'thor/runner'

if Delphivm::ROOT == Pathname(__FILE__).dirname.parent
  TARGET = Object.const_get('Delphivm')
else
  VersionInfo.file_format = :text
  target = Module.new
  target.module_exec do
    include VersionInfo
    self.VERSION.file_name = Delphivm::ROOT + 'VERSION'
  end
  Object.const_set(ROOT.basename.to_s, target)
  target.freeze
  VersionInfo.install_tasks(:target => target)

  TARGET = Object.const_get(target.name)
end

module Thor::Util #:nodoc:
  SEARCH_ROOT = File.dirname(__FILE__)
  # redefine to search tasks only for this app
  def self.globs_for(path)
    ["#{SEARCH_ROOT}/tasks/*.thor"]
  end
end

class Delphivm
  EXE_NAME = File.basename($0, '.rb')
  
  PATH_TO_VENDOR = ROOT + 'vendor'
  PATH_TO_VENDOR_CACHE = PATH_TO_VENDOR + 'cache'
  PATH_TO_VENDOR_IMPORTS = PATH_TO_VENDOR + 'imports'

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
