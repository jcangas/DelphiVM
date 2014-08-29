# encoding: UTF-8
class Vendor < DvmTask
  include Thor::Actions
  
  desc "init", "create and initialize vendor directory"
  def init
    vendor_path = PATH_TO_VENDOR
    empty_directory vendor_path
    empty_directory vendor_path + 'cache'
    empty_directory vendor_path + 'imports'
    create_file(DVM_IMPORTS_FILE, :skip => true) do <<-EOS
# sample imports file for delphivm

# set source url
source "my_imports_path"

# can use environment vars anywhere
# source "\#{ENV['IMPORTS_PATH']}"

# set IDE version
uses 'D150'

# now, you can declare some imports

import "FastReport", "4.13.1" do
  ide_install('dclfs15.bpl','dclfsADO15.bpl', 'dclfsBDE15.bpl', 'dclfsDB15.bpl', 'dclfsIBX15.bpl',
    'dclfsTee15.bpl', 'dclfrxADO15.bpl', 'dclfrxBDE15.bpl', 'dclfrxDBX15.bpl', 'dclfrx15.bpl',
    'dclfrxDB15.bpl', 'dclfrxTee15.bpl', 'dclfrxe15.bpl', 'dclfrxIBX15.bpl')
end

# or if we don't need ide install

import "TurboPower", "7.0.0" 



# repeat for other sources and/or IDEs

EOS
    end
  end
  
  desc "import", "download and install vendor imports"
  method_option :clean,  type: :boolean, aliases: '-c', default: false, desc: "clean cache first"
  def import
    clean_vendor(options) if options.clean?
    prepare
    silence_warnings{DSL.run_imports_dvm_script(DVM_IMPORTS_FILE)}
    deploy_vendor if options.deploy?
  end

  desc "clean", "Clean imports. Use -c (--cache) to also clean downloads cache"
  method_option :cache,  type: :boolean, aliases: '-c', default: false, desc: "also clean cache"
  def clean
    clean_vendor(options)
    prepare
  end

private

  def clean_vendor(opts)
    remove_dir(PATH_TO_VENDOR_IMPORTS)
    remove_dir PATH_TO_VENDOR_CACHE if opts.cache?
  end

  def prepare
    empty_directory PATH_TO_VENDOR_CACHE
    empty_directory PATH_TO_VENDOR_IMPORTS
  end	
end
