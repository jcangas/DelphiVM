
class Delphivm
  # Domain specific language for imports script
  module DSL
    def self.load_dvm_script(path_to_file, options = {}, required_by = nil)
      ImportScript.new(path_to_file, options, required_by)
    end

    def self.multi_dvm_scripts(pattern, options = {}, required_by = nil)
      group_script = ImportScript.new(PRJ_IMPORTS_FILE)
      group_script.source(PRJ_ROOT)
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
        prjdef = group_script.import(libname, version)
        prjdef.dependences_scriptname = subprj
      end
      group_script
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
        @file_name = file_name
        @loaded = file_name.exist?
        if @loaded
          eval(File.read(file_name))
          collect_dependences
        end
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

      protected

      def tree(max_level, format, visited = [])
        foreach_do :tree, [max_level, format, visited], true
      end

      def proccess
        foreach_do :proccess
      end

      def ide_install
        foreach_do :do_ide_install
      end

      def collect_dependences
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

      def satisfied(lib_tag)
        lib_tag = lib_tag.to_sym
        result = false
        parent_result = false
        result = true if @imports.has_key?(lib_tag) && @imports[lib_tag].satisfied?
        parent_result = true if required_by && required_by.script.satisfied(lib_tag)
        result ||= parent_result
        result
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
        @dependences_scriptname =  script.file_name.dirname + 'vendor' + lib_tag + IMPORTS_FNAME
        @satisfied = false
        instance_eval(&block) if block
      end

      def lib_tag
        "#{libname}-#{libver}"
      end

      def lib_file
        "#{lib_tag}-#{idever}.zip"
      end

      # import.dvm file must exist in vendor
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
        @satisfied
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
          search = (PRJ_ROOT + 'out' + idever + 'Win32' + '{Release,Debug}' + 'bin' + ide_pkg)

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
        fail "import's source undefined" unless @source
        return if (idevers & script.options[:idevers]).empty?
        destination = DVM_IMPORTS + idever
        cache_folder = destination + lib_tag
        exist = cache_folder.exist?
        already_in_tree = script.send(:satisfied, lib_tag)
        if exist && script.options.force? && !already_in_tree
          exist = false
          FileUtils.remove_dir(cache_folder.win, true)
        end
        status = exist ? :'cached in' : :'fetch to'
        say
        say "[#{script.level}] Importing #{lib_file}", [:blue, :bold]
        say_status status, "#{destination.win}", :green

        zip_file = download(source_uri, lib_file) unless exist
        exist ||= zip_file
        exist ? @satisfied = true : @satisfied = false
        return if defined? Ocra

        unzip(zip_file, destination) if zip_file
        return unless exist
        vendorize
        ensure_dependences_script
        dependences_script.send(:foreach_do, :proccess)
      end

      def show_ide_install_report(report)
        say_status(:IDE, "#{lib_tag} installed #{report[:ok].count} packages", :green) unless report[:ok].empty?
        unless report[:fail].empty?
          say_status :IDE, 'missing packages:', :red
          say report[:fail].join("\n")
        end
      end

      def get_vendor_files
        Pathname.glob(DVM_IMPORTS + idever + lib_tag + '**/*')
      end

      def vendorized?
        dependences_scriptname.exist?
      end

      def vendorize
        if vendorized?
          say_status :skip, "#{lib_file}, already in vendor", :yellow
          return
        end
        files = get_vendor_files
        pb = ProgressBar.create(total: files.size, title: '  %9s ->' % 'vendorize', format: '%t %J%% %E %B')
        files.each do |file|
          next if file.directory?
          route = file.relative_path_from(DVM_IMPORTS + idever)
          link = PRJ_IMPORTS + route
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

      def tree_uml(max_level, visited)
        if script.required_by
          link = "[#{script.required_by.lib_tag}] --> [#{lib_tag}]"
          say link unless visited.include?(link)
          visited << link
        end
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
