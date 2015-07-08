require 'version_info'

$LOAD_PATH << Pathname(__FILE__).dirname + 'lib'

require 'delphivm/version'

VersionInfo.install_tasks(:target => Delphivm)

class Prj < Thor

  desc "build", "compile script with ocra"
  method_option :bump, type: :boolean, aliases: '-b', default: false, desc: "bump version patch"
  method_option :inno, type: :boolean, aliases: '-i', default: true, desc: "use Inno Setup installer"
  def build
    if options[:bump]
      invoke("vinfo:bump")
      reload_version
    end
    upd_iss
    root = Pathname.getwd
    (root + 'out').mkpath
   # system "ocra --icon delphi_PROJECTICON.ico --debug-extract --output ./out/DelphiVM.exe --no-enc --gem-full=bundler --console bin\\delphivm lib\\**\\*.thor"
   if options.inno?
     system "ocra --output ./out/DelphiVM.exe --icon installer/delphivm.ico --no-enc --gem-full=bundler --no-lzma --chdir-first --innosetup installer/delphivm.iss --console bin\\delphivm lib\\**\\*.thor"
   else
     system "ocra --output ./out/DelphiVM.exe --icon installer/delphivm.ico --no-enc --gem-full=bundler --console bin\\delphivm lib\\**\\*.thor"
   end
  end
  private
    def reload_version
      if Object.const_defined?("Delphivm")
       Object.send(:remove_const, "Delphivm")
      end
      $".delete_if {|s| s.include?('delphivm') }
      require 'delphivm/version'
    end

    def upd_iss
      content = File.readlines('installer/delphivm.iss')
      content.shift
      content.unshift %Q{# define VERSION "#{Delphivm.VERSION}"\n}
      File.open('installer/delphivm.iss', "w") do |file|
        file.write content.join
      end
    end
end

class Default < Thor
  desc "test", "run tests"
  def test
    say %x[ruby spec/spec_helper.rb]
  end
end
