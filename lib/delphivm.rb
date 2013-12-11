#!/usr/bin/env ruby

require 'thor'
Delphivm = Thor # sure, we are hacking Thor !


require 'pathname'
require 'extensions'

require 'version_info'

require 'delphivm/configuration'
require 'delphivm/version'

class Delphivm
  module Talk
    def self.included(other)
      super
      other.extend self
    end

    def say(*args)
      Delphivm.shell.say(*args)
    end
  end
    
  include Configurable

  ROOT = ::Pathname.getwd
  GEM_ROOT = Pathname(__FILE__).dirname.parent
  EXE_NAME = File.basename($0, '.rb')

  DEFAULT_CFG_FILE = $0 + '.cfg'

 	PATH_TO_VENDOR = ROOT + 'vendor'
  PATH_TO_VENDOR_CACHE = PATH_TO_VENDOR + 'cache'
  PATH_TO_VENDOR_IMPORTS = PATH_TO_VENDOR + 'imports'
  DVM_IMPORTS_FILE = ROOT + 'imports.dvm'
  DELPHIVM_DEFAULTS = 
    {known_ides: 
      {
        'D100' => {regkey: 'Software\Borland\BDS\4.0', name: '2006', desc: 'Borland Developer Stuido 4.0'},
        'D150' => {regkey: 'Software\Embarcadero\BDS\8.0', name: 'XE', desc: 'Embarcadero RAD Stuido XE', msbuild_args: "/nologo /consoleloggerparameters:v=quiet"},
        'D160' => {regkey: 'Software\Embarcadero\BDS\9.0', name: 'XE2', desc: 'Embarcadero RAD Stuido XE2'},
        'D170' => {regkey: 'Software\Embarcadero\BDS\10.0', name: 'XE3', desc: 'Embarcadero RAD Stuido XE3'},
        'D180' => {regkey: 'Software\Embarcadero\BDS\11.0', name: 'XE4', desc: 'Embarcadero RAD Stuido XE4'},
        'D190' => {regkey: 'Software\Embarcadero\BDS\12.0', name: 'XE5', desc: 'Embarcadero RAD Stuido XE5'},
      },
      msbuild_args: "/nologo /consoleloggerparameters:v=quiet /filelogger /flp:v=detailed"
    }

  def self.shell
    @shell ||= Thor::Base.shell.new
  end

private
  def self.create_app_module
    @app_module = ::Module.new do
      VersionInfo.file_format = :text
      include VersionInfo
      self.VERSION.file_name = ROOT + 'VERSION'
    end
    Object.const_set(ROOT.basename.to_s.snake_case.camelize, @app_module)
    @app_module.freeze
  end  

  def self.app_module
    return @app_module if defined?(@app_module) && @app_module
    if ROOT.basename.to_s.casecmp(EXE_NAME) == 0
      @app_module = self
      VersionInfo.file_format = :module # para reportar la propia
    else
      create_app_module
    end
    VersionInfo.install_tasks(:target => @app_module)
    @app_module
  end
public
  APPMODULE = self.app_module
  self.configure(DELPHIVM_DEFAULTS).load(DEFAULT_CFG_FILE)
  APP_ID = "#{::Delphivm::APPMODULE}-#{::Delphivm::APPMODULE.VERSION.tag}"
end


# pretty alias to define custom tasks
DvmTask = Delphivm

# Runner must be loaded after Delphivm setup, i.e., after Thor is hacked 
require 'delphivm/runner'
