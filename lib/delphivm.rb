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

  # for Innosetup ->
  Dir.chdir(ENV["DVM_PRJDIR"]) if ENV["DVM_PRJDIR"]

  PRJ_ROOT = ::Pathname.getwd
  GEM_ROOT = Pathname(__FILE__).dirname.parent
  EXE_NAME = 'DelphiVM'

  DVM_DATA = Pathname(ENV["APPDATA"].gsub('\\','/')) + EXE_NAME
  DVM_DATA.mkpath

  DVM_TEMP = Pathname(ENV["TEMP"].gsub('\\','/')).realpath
  DVM_TEMP.mkpath

  DVM_CFG_FILE =  DVM_DATA + 'DelphiVM.cfg'
  DVM_IMPORTS = DVM_DATA + 'imports'
  DVM_IMPORTS.mkpath

  PRJ_IMPORTS_FILE = PRJ_ROOT + 'imports.dvm'
  PRJ_CFG_FILE = PRJ_ROOT + 'DelphiVM.cfg'
  PRJ_IMPORTS = PRJ_ROOT + 'vendor'
  
  def self.shell
    @shell ||= Thor::Base.shell.new
  end

private
  def self.create_app_module
    @app_module = ::Module.new do
      VersionInfo.file_format = :module
      include VersionInfo
    end
    Object.const_set(PRJ_ROOT.basename.to_s.snake_case.camelize, @app_module)
    @app_module.VERSION.file_name = PRJ_ROOT + 'VERSION.pas'
    @app_module.VERSION.load
    @app_module.freeze
  end

  def self.app_module
    return @app_module if defined?(@app_module) && @app_module
    if PRJ_ROOT.basename.to_s.casecmp(EXE_NAME) == 0
      @app_module = self
      VersionInfo.file_format = :module # para reportar la propia vinfo
    else
      create_app_module
    end
    VersionInfo.install_tasks(:target => @app_module)
    @app_module
  end
public
  APPMODULE = self.app_module
  self.configure.load(DVM_CFG_FILE, create: true)
  APP_ID = "#{::Delphivm::APPMODULE}-#{::Delphivm::APPMODULE.VERSION.tag}"

  def self.get_project_cfg
    unless @dvm_project_cfg ||= nil
      @dvm_project_cfg = Configuration.new
      @dvm_project_cfg.load(PRJ_CFG_FILE) if File.exist?(PRJ_CFG_FILE)
    end
    @dvm_project_cfg
  end
end


# pretty alias to define custom tasks
class DvmTask < Delphivm
  include PathMethods.extension(PRJ_ROOT)
  include Thor::Actions

  def self.inherited(klass)
	  klass.source_root(PRJ_ROOT)
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
      Delphivm.get_project_cfg.save(PRJ_CFG_FILE)
      say_status "writed!!", "file #{PRJ_CFG_FILE}"
    end
  end
end

# Runner must be loaded after Delphivm setup, i.e., after Thor is hacked
require 'delphivm/runner'
