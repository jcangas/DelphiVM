class Delphivm
  module DSL
    # unmarshalled script as Object
    class ImportScript < Object
      include Delphivm::Talk
      attr_reader :file_name
      attr_reader :required_by
      attr_reader :idever
      attr_reader :imports
      attr_reader :options
      attr_reader :loaded

      def initialize(file_name, options = {}, required_by = nil)
        @options = options
        @required_by = required_by
        @imports = {}
        load(file_name)
      end

      def load(file_name)
        # p "#{self.class}.load #{file_name}"
        @file_name = Pathname(file_name)
        @loaded = file_name.exist?
        return self unless @loaded
        instance_eval(File.read(file_name))
        collect_dependences
        self
      end

      def script_path
        file_name.dirname
      end

      def root_path
        return @root_path if @root_path
        if multi_root || multi_top_prj
          file_name.dirname
        else
          required_by.script.root_path
        end
      end

      def prj_tag
        @prj_tag ||= "#{prj_name}-#{prj_version}"
      end

      def prj_version
        return @prj_version if @prj_version
        version_fname = root_path + 'version.pas'
        if version_fname.exist?
          lib_module = Module.new
          lib_module.module_eval(File.read(version_fname))
          @prj_version = lib_module::VERSION
        else
          @prj_version = '?.?.?'
        end
      end

      def prj_name
        root_path.basename
      end

      def vendor_path
        root_path + 'vendor'
      end

      def multi_root
        options.multi? && required_by.nil?
      end

      def multi_top_prj
        options.multi? && (required_by && required_by.script.multi_root) || required_by.nil?
      end

      def source(value = nil)
        value ? @source = Pathname(value.to_s.tr('\\', '/')) : @source
      end

      def uses(value, &block)
        @idever = value
        instance_eval(&block) if block
      end

      def import(libname, libver, liboptions = {}, &block)
        key = "#{libname}-#{libver}".to_sym
        if @imports.key?(key)
          @imports[key].idevers << @idever
          return
        end
        @imports[key] = Importer.new(self, libname, libver, liboptions, &block)
      end

      def level
        required_by ? required_by.script.level + 1 : 0
      end

      def idevers_filter
        return @idevers_filter if @idevers_filter
        IDEServices.root_path = script_path
        if multi_root
          ides_in_prj = IDEServices.idelist(:installed).map(&:to_s)
        else
          ides_in_prj = IDEServices.idelist(:prj).map(&:to_s)
        end
        @idevers_filter = options.idevers || []
        @idevers_filter =  ides_in_prj if @idevers_filter.empty?
        @idevers_filter &= ides_in_prj
      end

      def reset
        FileUtils.rm_r(vendor_path, verbose: false, force: true)
      end

      def prepare
        FileUtils.mkpath(vendor_path) unless multi_root
      end

      protected

      def tree(max_level, format, visited = [])
        foreach_do :tree, [max_level, format, visited], true
      end

      def proccess
        if multi_top_prj
          reset if options.reset?
          prepare
        end
        foreach_do :proccess
      end

      def ide_install
        foreach_do :do_ide_install
      end

      def collect_dependences
        return
        sorted_imports = {}
        imports.each do |lib_tag, importer|
          importer.dependences_script.collect_dependences
          importer.dependences_script.imports.each do |key, val|
            sorted_imports[key] = val unless sorted_imports.key?(key)
          end
          sorted_imports[lib_tag] = importer unless sorted_imports.key?(lib_tag)
        end
        @imports = sorted_imports
      end

      def foreach_do(method, args = [], owned = false)
        return unless method
        imports.values.each do |importdef|
          next if owned && importdef.script != self
          importdef.send method, *args
        end
      end

      def mark_fetch(lib_tag)
        if required_by.nil?
          @fetch_libs ||= {}
          @fetch_libs[lib_tag] = true
        else
          required_by.script.mark_fetch(lib_tag)
        end
      end

      def already_fetch(lib_tag)
        if required_by.nil?
          @fetch_libs ||= {}
          @fetch_libs.has_key?(lib_tag)
        else
          required_by.script.already_fetch(lib_tag)
        end
      end

      def mark_satisfied(lib_tag)
        if multi_top_prj
          @satisfied_libs ||= {}
          @satisfied_libs[lib_tag] = true
        else
          required_by.script.mark_satisfied(lib_tag)
        end
      end

      def satisfied(lib_tag)
        if multi_top_prj
          @satisfied_libs ||= {}
          @satisfied_libs.has_key?(lib_tag)
        else
          required_by.script.satisfied(lib_tag)
        end
      end
    end
  end
end
