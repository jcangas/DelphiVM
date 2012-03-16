#!/usr/bin/env ruby
# encoding: UTF-8
require "bundler/setup"
require 'thor'
require 'thor/runner'
require 'version_info'
require 'delphivm/version'
require 'open3'
require 'zip/zip'
require 'win32/registry.rb'

class ::Pathname 
  def glob(*args, &block)
    args[0] = (self + args[0]).to_s
    Pathname.glob(*args, &block)
  end

  def win
    self.to_s.gsub('/','\\')
  end
end

module Thor::Util #:nodoc:
  SEARCH_ROOT = File.dirname(__FILE__)
  # redefine to search tasks only for this app
  def self.globs_for(path)
    ["#{SEARCH_ROOT}/*.thor", "#{SEARCH_ROOT}/tasks/*.thor"]
  end
end

$0 = Pathname($0).basename('.rb').to_s
ROOT = Pathname.getwd

if ROOT == Pathname(__FILE__).dirname.parent
  TARGET = Object.const_get('Delphivm')
else
  VersionInfo.file_format = :text
  target = Module.new
  target.module_exec do
    include VersionInfo
    self.VERSION.file_name = ROOT + 'VERSION'
  end
  Object.const_set(ROOT.basename.to_s, target)
  target.freeze
  VersionInfo.install_tasks(:target => target)

  TARGET = Object.const_get(target.name)
end

module Delphivm
  EXE_NAME = File.basename($0, '.rb')
  class Runner < Thor::Runner
    namespace "\n"
    # remove some tasks not needed
    superclass.remove_task :install, :installed, :uninstall, :update
    
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
