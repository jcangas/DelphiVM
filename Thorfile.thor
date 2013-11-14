# encoding: UTF-8
require 'version_info'

$LOAD_PATH << Pathname(__FILE__).dirname + 'lib'
require 'delphivm/version'

VersionInfo.install_tasks(:target => Delphivm)

class Default < Thor
  desc "ocra", "compile script with ocra"
  def ocra
    root = Pathname.getwd
    (root + 'out').mkpath
    system "ocra --debug-extract --icon delphi_PROJECTICON.ico --output ./out/DelphiVM.exe --no-enc --gem-all --console bin\\delphivm **\\*.thor templates"
  end
end
