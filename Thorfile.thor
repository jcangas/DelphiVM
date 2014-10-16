require 'version_info'

$LOAD_PATH << Pathname(__FILE__).dirname + 'lib'
require 'delphivm/version'

VersionInfo.install_tasks(:target => Delphivm)

class Prj < Thor

  desc "build", "compile script with ocra"
  method_option :bump, type: :boolean, aliases: '-b', default: true, desc: "bump version patch"
  method_option :inno, type: :boolean, aliases: '-i', default: true, desc: "use Inno Setup installer"
  def build
    invoke("vinfo:bump") if options[:bump]
    root = Pathname.getwd
    (root + 'out').mkpath
   # system "ocra --icon delphi_PROJECTICON.ico --debug-extract --output ./out/DelphiVM.exe --no-enc --gem-full=bundler --console bin\\delphivm lib\\**\\*.thor"
   if options.inno?
     system "ocra --icon delphi_PROJECTICON.ico --output ./out/DelphiVM.exe --no-enc --gem-full=bundler --no-lzma --chdir-first --innosetup delphivm.iss --console bin\\delphivm lib\\**\\*.thor"
   else
     system "ocra --icon delphi_PROJECTICON.ico --output ./out/DelphiVM.exe --no-enc --gem-full=bundler --console bin\\delphivm lib\\**\\*.thor"
   end
  end

end

class Default < Thor
  desc "test", "run tests"
  def test
    say %x[ruby spec/spec_helper.rb]
  end
end
