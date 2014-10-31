class Vendor < DvmTask
  include Thor::Actions

  desc "init", "create and initialize vendor directory"
  def init
    create_file(PRJ_IMPORTS_FILE, :skip => true) do <<-EOS
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
  method_option :clean,  type: :boolean, aliases: '-c', default: false, desc: "clean prj vendor before import"
  method_option :sym,  type: :boolean, aliases: '-s', default: false, desc: "use symlinks"
  def import
    say "WARN: ensure your project folder supports symlinks!!" if options.sym?
    clean_vendor if options.clean?
    prepare
    silence_warnings{DSL.run_imports_dvm_script(PRJ_IMPORTS_FILE, options)}
  end

  desc "clean", "Clean vendor imports."
  def clean
    clean_vendor
    prepare
  end

private

  def clean_vendor
    remove_dir(PRJ_IMPORTS)
  end

  def prepare
    PRJ_IMPORTS.mkpath
  end
end
