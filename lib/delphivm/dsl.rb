require 'delphivm/dsl/import_script'
require 'delphivm/dsl/importer'

class Delphivm
  # Domain specific language for imports script
  module DSL
    def self.load_dvm_script(path_to_file, options = {}, required_by = nil)
      ImportScript.new(path_to_file, options, required_by)
    end

    def self.new_dvm_script(root_path, options = {}, required_by = nil)
      path_to_file = Pathname(root_path) + IMPORTS_FNAME
      root_script = ImportScript.new(path_to_file, options, required_by)
      return root_script unless options.multi?
      root_script.source(root_path)
      pattern = Pathname(root_path) + '*' + IMPORTS_FNAME
      Pathname.glob(pattern).each do |subprj|
        libname = subprj.dirname.basename
        version_fname = subprj.dirname + 'version.pas'
        if version_fname.exist?
          lib_module = Module.new
          lib_module.module_eval(File.read(version_fname))
          version = lib_module::VERSION
        else
          version = '?.?.?'
        end
        prjdef = root_script.import(libname, version)
        prjdef.dependences_scriptname = subprj
      end
      root_script
    end
  end
end
