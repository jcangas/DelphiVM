require 'spec_helper'

TestScript = <<-END
source 'http://example.com'
uses 'D200'
  import 'SummerFw4D', '0.8.5' do
    ide_install('SummerFW.Utils190.bpl')
  end
END

describe "Registry" do
  # stub seems don't work on Thor task methods, so fake the class under test
  load File.join('dvm', "registry.thor")
  class FakeRegistry < Registry
    desc "",""
    def directory(a,b)
    end
  end

  it "copy works" do
    idever = Delphivm::IDEServices.default_ide
    ide = Delphivm::IDEServices.new(idever)
    tt_slug = 'template'
    prj_slug = 'test'
    out, err = capture_io do
      Delphivm::WinServices.stub :system, lambda{|cmd| cmd} do
        FakeRegistry.start(%W[copy #{idever} -t #{tt_slug} -k #{prj_slug}])
      end
    end
    version = Pathname(ide.ide_regkey).basename
    path_src = Pathname(ide.ide_regkey).parent.parent + ide.prj_regkey(tt_slug).upcase + version
    path_dest = Pathname(ide.ide_regkey).parent.parent + ide.prj_regkey(prj_slug) + version
    assert_equal %Q(reg copy "hkcu\\#{path_src.win}" "hkcu\\#{path_dest.win}" /s /f\n), out
  end
end

describe "Importer" do
  it "only register Win32 packages" do
      script = Delphivm::DSL::ImportScript.new(TestScript)
      called = false
      stub_register = lambda do |idever, pkg|
        called = true
        platform = 'Win32'
        config = 'Debug'
        assert_equal 'D200', idever
        assert_equal Delphivm::PATH_TO_VENDOR_IMPORTS + idever + platform + config + 'bin' +  'SummerFW.Utils190.bpl', pkg
        nil
      end
      importer = script.imports.first
      importer.stub :download, true do
        importer.stub :unzip, nil do
          importer.stub :register, stub_register do
            importer.send :proccess
            assert called, "register must be called"
          end
        end
      end
  end

end
