
class Delphivm
  module DSL
    def self.run_imports_dvm_script(path_to_file, options = {})
      read_imports_dvm_script(path_to_file, options).foreach_do :proccess
    end

    def self.register_imports_dvm_script(path_to_file, options = {})
      read_imports_dvm_script(path_to_file, options).foreach_do :proccess_ide_install
    end

    def self.read_imports_dvm_script(path_to_file, options = {})
      ImportScript.new(File.read(path_to_file), options)
    end

    class ImportScript < Object
      attr_reader :idever
      attr_reader :imports
      attr_reader :options

      def initialize(script = '', options = {})
        @imports = {}
        @options = options
        eval(script)
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
        unless @imports.has_key?(key)
          @imports[key] = Importer.new(self, libname, libver, liboptions, &block)
        end
      end

      def foreach_do(method)
        imports.values.each do |imp|
          imp.send method
        end
      end
    end

    class Importer
      include Delphivm::Talk
      attr_reader :script
      attr_reader :source
      attr_reader :idever
      attr_reader :configs
      attr_reader :libname
      attr_reader :libver
      attr_reader :ide_pkgs

      def initialize(script, libname, libver, liboptions = {}, &block)
        @script = script
        @source = script.source
        @idever = script.idever
        @libname = libname
        @libver = libver
        @configs = liboptions[:config]
        @configs ||= ''
        @configs = %w(Release Debug) if configs == '*'
        @configs = [configs] unless configs.is_a? Array
        @ide_pkgs = []
        instance_eval(&block) if block
      end

      def lib_tag
        "#{libname}-#{libver}"
      end

      private

      def ide_install(*packages)
        @ide_pkgs = packages
      end

      def proccess_ide_install
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
            register(idever, target)
            say "IDE library {target.basename} (#{use_config}) installed"
          else
            say "IDE library #{pkg} not found !!"
          end
        end
      end

      def proccess
        fail "import's source undefined" unless @source
        lib_file = "#{lib_tag}-#{idever}.zip"
        destination = DVM_IMPORTS + idever
        cache_folder = destination + lib_tag
        exist = cache_folder.exist?
        if exist && script.options.force?
          exist = false
          FileUtils.remove_dir(cache_folder.win, true)
        end
        status = exist ? :cached : :fetch
        puts # for easy console read      
        say_status status, "Importing #{lib_file} to #{destination.win}", :green
        zip_file = download(source, lib_file) unless exist
        return if defined? Ocra
        unzip(zip_file, destination) if zip_file
        exist ||= zip_file
        return unless exist
        vendorize
        proccess_dependences
        proccess_ide_install
        say_status :done, lib_file, :green
      end
      
      def proccess_dependences
        dvm_file = Pathname(PRJ_IMPORTS  + lib_tag + 'imports.dvm')
        DSL.run_imports_dvm_script(dvm_file, script.options) if dvm_file.exist?
      end
      
      
      def get_vendor_files
        Pathname.glob(DVM_IMPORTS + idever + lib_tag + '**/*')
      end

      def vendorized?
        # check any src file is present
        files = Pathname.glob(DVM_IMPORTS + idever + lib_tag + 'src/**/*.{dpr,dpk}')
        return false if files.empty?
        file = files.first
        route = file.relative_path_from(DVM_IMPORTS + idever)
        link = PRJ_IMPORTS + route
        return true if link.exist?
        # check any bin file is present
        files = Pathname.glob(DVM_IMPORTS + idever + lib_tag + 'out/**/*.{exe,bpl,dll}')
        return false if files.empty?
        file = files.first
        route = file.relative_path_from(DVM_IMPORTS + idever)
        link = PRJ_ROOT + 'out' + idever + route
        link.exist?
      end

      def vendorize
        lib_file = "#{lib_tag}-#{idever}.zip"
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

      def register(idever, pkg)
        ide_prj = IDEServices.new(idever)
        WinServices.reg_add(key: ide_prj.pkg_regkey, value: pkg.win, data: ide_prj.prj_slug, force: true)
      end

      def download(source_uri, file_name)
        full_url = Pathname(source_uri) + file_name
        unless full_url.exist?
          say_status :ERROR, "#{file_name} not found", :red
          return nil
        end
        to_here = DVM_TEMP + file_name
        to_here.delete if to_here.exist?
        pb = nil
        start = lambda { |length| pb = ProgressBar.create(total: length, title: '  %9s ->' % 'download', format: '%t %J%% %E %B'); pb.file_transfer_mode }
        progress = lambda { |s| pb.progress = s; pb.refresh }

        begin
          content = open(full_url, 'rb', content_length_proc: start, progress_proc: progress).read
          File.open(to_here, 'wb') { |wfile| wfile.write(content) } unless defined? Ocra
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
            yield f_path if block_given?
          end
        end
        pb.finish
      end
    end
  end
end
