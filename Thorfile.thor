# encoding: UTF-8
require 'version_info'

$LOAD_PATH << Pathname(__FILE__).dirname + 'lib'
require 'delphivm/version'

VersionInfo.install_tasks(:target => Delphivm)

class Build < Thor
  desc "ocra", "compile script with ocra"
  def ocra
    root = Pathname.getwd
    (root + 'out').mkpath
    system "ocra --icon delphi_PROJECTICON.ico --output ./out/DelphiVM.exe  --no-enc --gem-full --console bin\\delphivm.rb **\\*.thor"
  end
end
