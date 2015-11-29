
class Delphivm
  module DSL
    def self.run_imports_dvm_script(path_to_file, options = {})
      read_imports_dvm_script(path_to_file, options).foreach_do :proccess
    end

    def self.register_imports_dvm_script(path_to_file, options = {})
      read_imports_dvm_script(path_to_file, options).foreach_do :proccess_ide_install
    end

    def self.read_imports_dvm_script(path_to_file, options = {})
      script = ImportScript.new(File.read(path_to_file), path_to_file, options)
    end

    class ImportScript < Object
      attr :idever
      attr :imports
      attr :options

      def initialize(script="", path_to_file = __FILE__, options={})
        @imports = []
        @options = options
        #eval(script, binding, path_to_file, 1) # aparentemente no va
        eval(script)
      end

      def source(value = nil)
        value ? @source = Pathname(value.to_s.gsub('\\','/')) : @source
      end

      def uses(value, &block)
        @idever = value
        instance_eval(&block) if block
      end

      def import(libname, libver, liboptions={}, &block)
        @imports << Importer.new(self, libname, libver, liboptions, &block)
      end

      def foreach_do(method)
        self.imports.each do |imp|
          imp.send method
        end
      end
    end

    class Importer
      attr :script
      attr :source
      attr :idever
      attr :configs
      attr :libname
      attr :libver
      attr :ide_pkgs

      def initialize(script, libname, libver, liboptions={}, &block)
        @script = script
        @source = script.source
        @idever = script.idever
        @libname = libname
        @libver = libver
        @configs = liboptions[:config]
        @configs ||= ''
        @configs = ['Release', 'Debug'] if configs == '*'
        @configs = [configs] unless configs.is_a?Array
        @block = block
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
          use_config = (avaible_configs.include?(prefer_config) ? prefer_config : avaible_configs.first)
          target = avaiable_files[use_config]
          if target
            register(idever, target)
            puts "IDE library {target.basename} (#{use_config}) installed"
          else
            puts "IDE library #{pkg} not found !!"
          end
        end
      end

      def proccess
        raise "import's source undefined" unless @source
        block = @block
        configs.each do |config|
          cfg_segment = config.strip
          cfg_segment = "-#{cfg_segment}" unless cfg_segment.empty?
          lib_file = "#{lib_tag}-#{idever}#{cfg_segment}.zip"
          destination = DVM_IMPORTS + idever
          cache_folder = destination + lib_tag
          exist = cache_folder.exist?
          if exist && script.options.force?
            exist = false
            FileUtils.remove_dir(cache_folder.win, true)
          end
          puts "#{exist ? '(cached) ':''}Importing #{lib_file} to #{destination.win}"
          unless exist
            if zip_file = download(source, lib_file)
              unzip(zip_file, destination) unless defined? Ocra
            end
          end
          unless defined? Ocra
            if vendorized?(get_vendor_files_check)
              puts "(skip) #{lib_file}, already in vendor"
            else
              vendorize(get_vendor_files)
            end
          end
        end
        proccess_ide_install
      end

      def get_vendor_files_check
        Pathname.glob(DVM_IMPORTS + idever + lib_tag + 'src/**/*.{dpr,dpk}')
      end

      def get_vendor_files
        Pathname.glob(DVM_IMPORTS + idever + lib_tag + '**/*')
      end

      def vendorized?(files)
        return false if files.empty?
        file = files.first
        route = file.relative_path_from(DVM_IMPORTS + idever)
        link = PRJ_IMPORTS + route
        link.exist?
      end

      def vendorize(files)
        pb = ProgressBar.create(:total =>  files.size, title: '  %9s ->' % 'vendorize', format: "%t %J%% %E %B")
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
        #puts "#{link} --> #{target}";return
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
        to_here = DVM_TEMP + file_name
        to_here.delete if to_here.exist?
        pb = nil
        start = lambda { |length| pb = ProgressBar.create(total: length, title: '  %9s ->' % 'download', format: "%t %J%% %E %B"); pb.file_transfer_mode }
        progress = lambda {|s| pb.progress = s; pb.refresh}

        begin
          #start.call(full_url.size)
          content = open(full_url, "rb", content_length_proc: start, progress_proc: progress).read
          File.open(to_here, "wb") {|wfile|  wfile.write(content) } unless defined? Ocra
        rescue Exception => e
          puts e
          return nil
        end

        return to_here
      ensure
          pb.finish if pb
      end

      def unzip(file, destination)
        pb = ProgressBar.create(:total =>  file.size, title: '  %9s ->' % 'install', format: "%t %J%% %E %B")
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
