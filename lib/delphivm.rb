#!/usr/bin/env ruby

require 'thor'
require 'pathname'
require 'extensions'

require 'version_info'
require 'delphivm/configuration'

Delphivm = Thor # sure, we are hacking Thor !
class Delphivm
  include(VersionInfo)
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
        'D150' => {regkey: 'Software\Embarcadero\BDS\8.0', name: 'XE', desc: 'Embarcadero RAD Stuido XE'},
        'D160' => {regkey: 'Software\Embarcadero\BDS\9.0', name: 'XE2', desc: 'Embarcadero RAD Stuido XE2'},
        'D170' => {regkey: 'Software\Embarcadero\BDS\10.0', name: 'XE3', desc: 'Embarcadero RAD Stuido XE3'},
        'D180' => {regkey: 'Software\Embarcadero\BDS\11.0', name: 'XE4', desc: 'Embarcadero RAD Stuido XE4'},
        'D190' => {regkey: 'Software\Embarcadero\BDS\12.0', name: 'XE5', desc: 'Embarcadero RAD Stuido XE5'},
      },
      msbuild_args: "/nologo /consoleloggerparameters:v=quiet /filelogger /flp:v=detailed"
    }

  
  class Gen < Thor
    namespace :gen
    # used only as thor namesapce for generators
    # defined here because we need ensure class Gen exist when generator tasks are loaded
    desc "echo", "prueba de echo"
    def echo
    end
  end

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
  self.configure(DELPHIVM_DEFAULTS).load(DEFAULT_CFG_FILE)
end

# Runner must be loaded after Delphivm setup, i.e., after Thor is hacked 
require 'delphivm/runner'
