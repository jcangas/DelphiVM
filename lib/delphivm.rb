#!/usr/bin/env ruby
require 'thor'
Delphivm = Thor # sure, we are hacking Thor !


require 'pathname'
require 'extensions'

require 'version_info'
require 'path_methods'
require 'configuration'
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

  DEFAULT_CFG_FILE = Pathname($0 + '.cfg')
  DVM_PRJ_CFG = ROOT + DEFAULT_CFG_FILE.basename

  DVM_IMPORTS_FILE = ROOT + 'imports.dvm'
  PATH_TO_VENDOR_CACHE = Pathname($0).dirname + 'dvm-cache'
  PATH_TO_VENDOR = ROOT + 'vendor'
  PATH_TO_VENDOR_IMPORTS = PATH_TO_VENDOR + 'imports'
  DELPHIVM_DEFAULTS =
    {known_ides:
      {
        'D100' => {regkey: 'Software\Borland\BDS\4.0', name: '2006', desc: 'Borland Developer Stuido 4.0'},
        'D150' => {regkey: 'Software\Embarcadero\BDS\8.0', name: 'XE', desc: 'Embarcadero RAD Stuido XE', msbuild_args: "/nologo /consoleloggerparameters:v=quiet"},
        'D160' => {regkey: 'Software\Embarcadero\BDS\9.0', name: 'XE2', desc: 'Embarcadero RAD Stuido XE2'},
        'D170' => {regkey: 'Software\Embarcadero\BDS\10.0', name: 'XE3', desc: 'Embarcadero RAD Stuido XE3'},
        'D180' => {regkey: 'Software\Embarcadero\BDS\11.0', name: 'XE4', desc: 'Embarcadero RAD Stuido XE4'},
        'D190' => {regkey: 'Software\Embarcadero\BDS\12.0', name: 'XE5', desc: 'Embarcadero RAD Stuido XE5'},
        'D200' => {regkey: 'Software\Embarcadero\BDS\14.0', name: 'XE6', desc: 'Embarcadero RAD Stuido XE6'},
        'D210' => {regkey: 'Software\Embarcadero\BDS\15.0', name: 'XE7', desc: 'Embarcadero RAD Stuido XE7'},
      },
      msbuild_args: "/nologo /consoleloggerparameters:v=quiet /filelogger /flp:v=detailed"
    }

  def self.shell
    @shell ||= Thor::Base.shell.new
  end

private
  def self.create_app_module
    @app_module = ::Module.new do
      VersionInfo.file_format = :module
      include VersionInfo
    end
    Object.const_set(ROOT.basename.to_s.snake_case.camelize, @app_module)
    @app_module.VERSION.file_name = ROOT + 'VERSION.pas'
    @app_module.VERSION.load
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
  self.configure(DELPHIVM_DEFAULTS).load(DEFAULT_CFG_FILE, create: true)
  APP_ID = "#{::Delphivm::APPMODULE}-#{::Delphivm::APPMODULE.VERSION.tag}"

  def self.get_project_cfg
    unless @dvm_project_cfg ||= nil
      @dvm_project_cfg = Configuration.new
      @dvm_project_cfg.load(DVM_PRJ_CFG) if File.exists?(DVM_PRJ_CFG)
    end
    @dvm_project_cfg
  end
end


# pretty alias to define custom tasks
class DvmTask < Delphivm
  include PathMethods.extension(ROOT)
  include Thor::Actions

  def self.inherited(klass)
	   klass.source_root(ROOT)
     klass.publish unless klass == BuildTarget
  end

protected
  class << self

    def configuration
      Delphivm.get_project_cfg.tasks do |tasks|
        tasks.send(self.namespace+'!', Configuration.new)
      end
      Delphivm.get_project_cfg.tasks[self.namespace]
    end

    def configure
      if block_given?
        yield(self.configuration)
      else
        self.configuration
      end
    end

    def publish
      [:cfg].each do |mth|
        desc "#{mth}", "show (--write) #{mth} for #{self.namespace}"
        method_option :write,  type: :boolean, aliases: '-w', default: false, desc: "write task setup to dvm prj file"
        define_method mth do
          do_setup
        end
      end
    end
  end


  def invocation
    _shared_configuration[:invocations][self.class].last
  end

  def meta_option(name)
    self.class.commands[self.invocation].options[name]
  end

  def option_invoked?(name)
    not (meta_option(name).default == options[name])
  end

  def do_setup
    say_status "configuration", "for #{self.class.namespace}"
    say self.class.configuration.to_h
    if options[:write]
      Delphivm.get_project_cfg.save(DVM_PRJ_CFG)
      say_status "writed!!", "file #{DVM_PRJ_CFG}"
    end
  end

end

# Runner must be loaded after Delphivm setup, i.e., after Thor is hacked
require 'delphivm/runner'
