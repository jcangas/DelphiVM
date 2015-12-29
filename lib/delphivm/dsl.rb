
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
        eval(File.read(file_name))
        collect_dependences
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
        FileUtils.mkpath(vendor_path)
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

      def mark_satisfied(lib_tag)
        @satisfied_libs ||= {}
        if multi_top_prj
          @satisfied_libs[lib_tag] = true
        else
          required_by.script.mark_satisfied(lib_tag)
        end
      end

      def satisfied(lib_tag)
        @satisfied_libs ||= {}
        if multi_top_prj
          @satisfied_libs.has_key?(lib_tag)
        else
          required_by.script.satisfied(lib_tag)
        end
      end
    end

    # Each import statement
    class Importer
      include Delphivm::Talk
      attr_reader :idevers
      attr_reader :script
      attr_reader :dependences_script
      attr_accessor :dependences_scriptname
      attr_reader :source
      attr_reader :source_uri
      attr_reader :idever
      attr_reader :libopts
      attr_reader :libname
      attr_reader :libver
      attr_reader :ide_pkgs

      def initialize(script, libname, libver, liboptions = {}, &block)
        @script = script
        @index = script.imports.size
        @idevers = [script.idever]
        @source = script.source
        @idever = script.idever
        @libname = libname
        @libver = libver
        @libopts = liboptions
        @source_uri = libopts[:uri] || Pathname(source) + lib_file
        @ide_pkgs = []
        @dependences_scriptname =  script.vendor_path + lib_tag + IMPORTS_FNAME
        @satisfied = false
        instance_eval(&block) if block
      end

      def lib_tag
        @llib_tag ||= "#{libname}-#{libver}"
      end

      def lib_file
        @lib_file ||= "#{lib_tag}-#{idever}.zip"
      end

      # import.dvm file must exist in vendor
      # in order to vendorize? method works
      def ensure_dependences_script
        fname = dependences_scriptname
        return if fname.exist?
        fname.dirname.mkpath
        fname.open('w')
      end

      def dependences_script
        unless @dependences_script && @dependences_script.loaded
          @dependences_script = DSL.load_dvm_script(dependences_scriptname, script.options, self)
        end
        @dependences_script
      end

      def satisfied?
        script.satisfied(lib_tag)
      end

      private

      def ide_install(*packages)
        @ide_pkgs = packages
      end

      def do_ide_install
        report = { ok: [], fail: [] }
        ide_pkgs.each do |ide_pkg|
          # El paquete para el IDE debe estar compilado para Win32
          # Preferir Release
          search = (script.root_path + 'out' + idever + 'Win32' + '{Release,Debug}' + 'bin' + ide_pkg)

          pkg_by_cfg = {}
          Pathname.glob(search).each_with_object(pkg_by_cfg) do |pkg, groups|
            groups[pkg.dirname.parent.basename.to_s] = pkg
          end

          target = pkg_by_cfg.values.first

          if target
            report[:ok] << ide_pkg
            register(idever, target)
          else
            report[:fail] << ide_pkg
          end
        end
        show_ide_install_report(report)
      end

      def proccess
        # p "#{lib_tag} proccess #{script.loaded}"
        return if already_in_tree = script.send(:satisfied, lib_tag)
        if script.multi_root # || script.multi_top_prj
          dependences_script.send(:proccess)
          return
        end
        fail "import's source undefined" unless @source
        net_idevers = (idevers & script.idevers_filter)
        return if net_idevers.empty?
        destination = DVM_IMPORTS + idever
        cache_folder = destination + lib_tag
        exist = cache_folder.exist?

        if exist && script.options.force? && !already_in_tree
          exist = false
          FileUtils.remove_dir(cache_folder.win, true)
        end
        status = exist ? :'cached in' : :'fetch to'
        say
        say "#{script.prj_name} Importing [#{script.level}] #{lib_file}", [:blue, :bold]
        say_status status, "#{destination.win}", :green

        zip_file = download(source_uri, lib_file) unless exist
        exist ||= zip_file
        mark_satisfied if exist
        return if defined? Ocra

        unzip(zip_file, destination) if zip_file
        return unless exist
        vendorize
        ensure_dependences_script
        dependences_script.send(:proccess)
      end

      def show_ide_install_report(report)
        say_status(:IDE, "#{lib_tag} installed #{report[:ok].count} packages", :green) unless report[:ok].empty?
        unless report[:fail].empty?
          say_status :IDE, 'missing packages:', :red
          say report[:fail].join("\n")
        end
      end

      def dvm_vendor_files
        Pathname.glob(DVM_IMPORTS + idever + lib_tag + '**/*')
      end

      def vendorized?
        dependences_scriptname.exist?
      end

      def vendorize
        # p "vendorize to #{script.vendor_path}"
        if vendorized?
          say_status :skip, "#{lib_file}, already in vendor", :yellow
          return
        end
        files = dvm_vendor_files
        pb = ProgressBar.create(total: files.size, title: '  %9s ->' % 'vendorize', format: '%t %J%% %E %B')
        files.each do |file|
          next if file.directory?
          route = file.relative_path_from(DVM_IMPORTS + idever)
          link = script.vendor_path + route
          install_vendor(link, file)
          pb.increment
        end
        pb.finish
      end

      def install_vendor(link, target)
        link.dirname.mkpath
        if @script.options.sym?
          WinServices.mklink(link: link.win, target: target.win)
        else
          FileUtils.cp(target, link)
        end
      end

      def tree(max_level, format, visited)
        send("tree_#{format}", max_level, visited)
        dependences_script.send(:tree, max_level, format, visited) if (max_level > script.level)
      end

      def mark_satisfied
        script.send(:mark_satisfied, lib_tag)
      end

      def tree_uml(max_level, visited)
        if script.multi_top_prj
          target = script.prj_tag
        else
          target = script.required_by.lib_tag
        end
        link = "[#{target}] --> [#{lib_tag}]"
        say link unless visited.include?(link)
        visited << link
      end

      def tree_draw(max_level, visited)
        if script.level == 0
          indent = ''
        else
          if @index == script.imports.size - 1
            head = "\u2514"
          else
            head = "\u251C"
          end
          indent = ' ' * 2 * (script.level - 1) + ' ' * (script.level - 1) + head + "\u2500 "
        end
        ides_installed = IDEServices.idelist(:installed).map(&:to_s)
        say "-#{"%2s" % script.level}:  ", [:yellow, :bold]
        say "#{indent}#{lib_tag} ", [:blue, :bold]
        idevers.each do |idever|
          ide_color = ides_installed.include?(idever) ? :green : :red
          say "#{idever} ", [ide_color, :bold]
        end
        say
      end

      def register(idever, pkg)
        ide_prj = IDEServices.new(idever)
        WinServices.reg_add(key: ide_prj.pkg_regkey, value: pkg.win, data: ide_prj.prj_slug, force: true)
      end

      def download(source_uri, file_name)
        to_here = DVM_TEMP + file_name
        to_here.delete if to_here.exist?
        pb = nil
        start = lambda do |length|
          pb = ProgressBar.create(total: length, title: '  %9s ->' % 'download', format: '%t %J%% %E %B')
        end
        progress = lambda do |s|
          pb.progress = s
        end
        begin
          open(source_uri, 'rb', content_length_proc: start, progress_proc: progress) do |reader|
            File.open(to_here, 'wb') do |wfile|
              while chunk = reader.read(1024)
                wfile.write(chunk) unless defined? Ocra
              end
            end
          end
        rescue Exception => e
          say_status :ERROR, e, :red
          return nil
        end

        return to_here
      ensure
        pb.finish if pb
      end

      def unzip(file, destination)
        pb = ProgressBar.create(total: file.size, title: '  %9s ->' % 'install', format: '%t %J%% %E %B')
        Zip::InputStream.open(file) do |zip_file|
          while (f = zip_file.get_next_entry)
            f_path = destination + f.name
            next if f_path.directory? || f.name =~ /\/$/
            f_path.dirname.mkpath
            pb.increment
            f.extract(f_path) unless f_path.exist?
          end
        end
        pb.finish
      end
    end
  end
end
