# encoding: UTF-8
require 'version_info'

$LOAD_PATH << Pathname(__FILE__).dirname + 'lib'
require 'delphivm/version'

VersionInfo.install_tasks(:target => Delphivm)


module Thor::Util
  SEARCH_ROOT = File.dirname(__FILE__)
  # redefine to search tasks only for this app   
  def self.load_thorfile(path, content=nil, debug=false)
  end
end

class Build < Thor
  desc "ocra", "compile script with ocra"
  def ocra
    root = Pathname.getwd
    (root + 'out').mkpath
    system "ocra --icon delphi_PROJECTICON.ico --output ./out/DelphiVM.exe  --no-enc --gem-full --console bin\\delphivm.rb **\\*.thor"
  end
end
