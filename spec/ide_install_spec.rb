require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/rg'

require 'delphivm'

TestScript = <<-END
source 'http://example.com'
uses 'D200'
  import 'SummerFw4D', '0.8.5' do
    ide_install('SummerFW.Utils190.bpl')
  end
END

describe "Importer" do
  it "IDE pkg must be in Win32" do
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

  it "can be created with a specific size" do
    Array.new(10).size.must_equal 10
  end
end
