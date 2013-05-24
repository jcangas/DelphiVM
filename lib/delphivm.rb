#!/usr/bin/env ruby

require 'thor'
require 'pathname'

require 'zip/zip'

require 'open3'
require 'nokogiri'

require 'win32/registry.rb'

require 'version_info'
require 'open-uri'
require 'net/http'
require 'ruby-progressbar'

require 'extensions'

require 'build_target'

Delphivm = Thor # sure, we are hacking Thor !

class Delphivm
  include(VersionInfo)

  ROOT = ::Pathname.getwd
  GEM_ROOT = Pathname(__FILE__).dirname.parent
  EXE_NAME = File.basename($0, '.rb')

 	PATH_TO_VENDOR = ROOT + 'vendor'
  PATH_TO_VENDOR_CACHE = PATH_TO_VENDOR + 'cache'
  PATH_TO_VENDOR_IMPORTS = PATH_TO_VENDOR + 'imports'
  DVM_IMPORTS_FILE = PATH_TO_VENDOR + 'imports.dvm'
  
  module Util #:nodoc:
    # redefine Thor to search tasks only for this app
    def self.globs_for(path)
      ["#{GEM_ROOT}/lib/dvm/**/*.thor", "#{Delphivm::ROOT}/dvm/**/*.thor"]
    end
  end

  class Gen < Thor
    namespace :gen
    # used only as thor namesapce for generators
    # defined here because we need ensure class Gen exist when generator tasks are loaded
    desc "echo", "prueba de echo"
    def echo
    end
  end

private
  def self.create_app_module
    @app_module = ::Module.new do
      include VersionInfo
      self.VERSION.file_name = ROOT + 'VERSION'
    end
    Object.const_set(ROOT.basename.to_s.snake_case.camelize, @app_module)
    @app_module.freeze # force to fix then module name
  end  

  def self.app_module
    return @app_module if @app_module
    if ROOT.basename.to_s.casecmp(EXE_NAME) == 0
      @app_module = Delphivm
    else
      create_app_module
    end
    VersionInfo.install_tasks(:target => @app_module)
    @app_module
  end
public
  APPMODULE = self.app_module
end

# Runner must be loaded after Delphivm setup, i.e., after Thor is hacked 
require 'delphivm/runner'
