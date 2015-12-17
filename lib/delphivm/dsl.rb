
class Delphivm
  module DSL
    def self.run_imports_dvm_script(path_to_file, options = {})
      load_dvm_script(path_to_file, options).send(:foreach_do, :proccess)
    end

    def self.register_imports_dvm_script(path_to_file, options = {})
      load_dvm_script(path_to_file, options).send(:foreach_do, :proccess_ide_install)
    end

    def self.load_dvm_script(path_to_file, options = {}, required_by = nil)
      if path_to_file.exist?
        content = File.read(path_to_file)
      else
        content = nil
      end
      ImportScript.new(content, options, required_by)
    end

    class ImportScript < Object
      include Delphivm::Talk
      attr_reader :required_by
      attr_reader :idever
      attr_reader :imports
      attr_reader :options
      attr_reader :loaded

      def initialize(content = nil, options = {}, required_by = nil)
        @loaded = (content != nil)
        @options = options
        @required_by = required_by
        @imports = {}
        return unless @loaded
        eval(content)
        collect_dependences
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

      def tree
        foreach_do :tree, true
      end

      def collect_dependences
        ordered_imports = {}
        imports.each do |lib_tag, importer|
          importer.dependences_script.collect_dependences
          importer.dependences_script.imports.each do |key, val|
            ordered_imports[key] = val unless ordered_imports.key?(key)
          end
          ordered_imports[lib_tag] = importer unless ordered_imports.key?(lib_tag)
        end
        @imports = ordered_imports
      end

      def foreach_do(method, owned = false)
        return unless method
        imports.values.each do |importdef|
          next if owned && importdef.script != self
          importdef.send method
        end
      end
    end

    class Importer
      include Delphivm::Talk
      attr_reader :idevers
      attr_reader :script
      attr_reader :dependences_script
      attr_reader :dependences_scriptname
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
        @dependences_scriptname = Pathname(PRJ_IMPORTS + lib_tag + 'imports.dvm')
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

      private

      def ide_install(*packages)
        @ide_pkgs = packages
      end

      def proccess_ide_install
        report = {ok: [], fail: []}
        packages = @ide_pkgs
        options = packages.pop if packages.last.is_a? Hash
        options ||= {}

        prefer_config = options[:config] || 'Release'
        packages.each do |pkg|
          # El paquete para el IDE debe estar compilado para Win32
          search_pattern = (PRJ_ROOT + 'out' + idever + 'Win32' + '{Debug,Release}' + 'bin' + pkg)
          avaiable_files = Pathname.glob(search_pattern).inject({}) do |mapped, p|
            mapped[p.dirname.parent.basename.to_s] = p
            mapped
          end
          avaible_configs = avaiable_files.keys
          use_prefer_config = avaible_configs.include?(prefer_config)
          use_config = (use_prefer_config ? prefer_config : avaible_configs.first)
          target = avaiable_files[use_config]
          if target
            report[:ok] << pkg
            register(idever, target)
          else
            report[:fail] << pkg
          end
        end
        report
      end

      def proccess
        fail "import's source undefined" unless @source
        return if (idevers & script.options[:idevers]).empty?
        destination = DVM_IMPORTS + idever
        cache_folder = destination + lib_tag
        exist = cache_folder.exist?
        if exist && script.options.force?
          exist = false
          FileUtils.remove_dir(cache_folder.win, true)
        end
        status = exist ? :'cached in' : :'fetch to'
        say
        say "[#{script.level}] Importing #{lib_file}", [:blue, :bold]
        say_status status, "#{destination.win}", :green

        zip_file = download(source_uri, lib_file) unless exist
        return if defined? Ocra
        unzip(zip_file, destination) if zip_file
        exist ||= zip_file
        return unless exist
        vendorize
        ensure_dependences_script
        dependences_script.send(:foreach_do, :proccess)
        report = proccess_ide_install
        say_status(:IDE, "installed packages: #{report[:ok].count}", :green) unless report[:ok].empty?
        unless report[:fail].empty?
          say_status :IDE, 'missing packages:', :red
          say report[:fail].join("\n")
        end
        #say "[#{script.level}] Import #{lib_file} done!", [:blue, :bold]
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
          if file.each_filename.include?('out')
            route = file.relative_path_from(DVM_IMPORTS + idever + lib_tag + 'out')
            link = PRJ_ROOT + 'out' + route
          else
            route = file.relative_path_from(DVM_IMPORTS + idever)
            link = PRJ_IMPORTS + route
          end
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

      def tree
        if script.level == 0
          indent = ''
        else
          #p @index
          if @index == script.imports.size - 1
            head = "\u2514"
          else
            head = "\u251C"
          end
          indent = ' ' * 2 * (script.level - 1) + ' ' * (script.level - 1) + head + "\u2500 "
        end
        say "-#{"%2s" % script.level}:  ", [:red, :bold]
        say "#{indent}#{lib_tag} ", [:green, :bold]
        say "#{idevers.join(', ')}", [:blue, :bold]
        dependences_script.send :tree
      end

      def register(idever, pkg)
        ide_prj = IDEServices.new(idever)
        WinServices.reg_add(key: ide_prj.pkg_regkey, value: pkg.win, data: ide_prj.prj_slug, force: true)
      end

      def download(source_uri, file_name)
        #  Esto solo es valido para ficheros, no uris en gral
        # unless source_uri.exist?
        #   say_status :ERROR, "#{file_name} not found", :red
        #   return nil
        # end
        to_here = DVM_TEMP + file_name
        to_here.delete if to_here.exist?
        pb = nil
        start = lambda { |length| pb = ProgressBar.create(total: length, title: '  %9s ->' % 'download', format: '%t %J%% %E %B')}
        progress = lambda { |s| pb.progress = s; pb.refresh }
        begin
          content = open(source_uri, 'rb', content_length_proc: start, progress_proc: progress).read
          File.open(to_here, 'wb') { |wfile| wfile.write(content)} unless defined? Ocra
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
