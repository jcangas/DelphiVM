require 'version_info'

$LOAD_PATH << Pathname(__FILE__).dirname + 'lib'
require 'delphivm/version'

VersionInfo.install_tasks(:target => Delphivm)

class Prj < Thor

  desc "build", "compile script with ocra"
  def build
    invoke("vinfo:bump")
    root = Pathname.getwd
    (root + 'out').mkpath
   # system "ocra --icon delphi_PROJECTICON.ico --debug-extract --output ./out/DelphiVM.exe --no-enc --gem-full=bundler --console bin\\delphivm lib\\**\\*.thor"
    system "ocra --icon delphi_PROJECTICON.ico --output ./out/DelphiVM.exe --no-enc --gem-full=bundler --console bin\\delphivm lib\\**\\*.thor"
  end

end

class Default < Thor
  desc "test", "run tests"
  def test
    say %x[ruby spec/spec_helper.rb]
  end
end
