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
   # system "ocra --icon delphi_PROJECTICON.ico --debug-extract --output ./out/DelphiVM.exe --no-enc --gem-full=bundler --console bin\\delphivm lib\\**\\*.thor"
    system "ocra --icon delphi_PROJECTICON.ico --output ./out/DelphiVM.exe --no-enc --gem-full=bundler --console bin\\delphivm lib\\**\\*.thor"
  end
end
