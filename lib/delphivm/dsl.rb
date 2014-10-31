
class Delphivm
  module DSL
    def self.run_imports_dvm_script(path_to_file, options = {})
      script = ImportScript.new(File.read(path_to_file), path_to_file, options)
      script.imports.each do |imp|
        imp.send :proccess
      end
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
    end

    class Importer
      attr :source
      attr :idever
      attr :configs
      attr :libname
      attr :libver

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
      end

      private

      def ide_install(*packages)
        options = packages.pop if packages.last.is_a? Hash
        options ||= {}

        prefer_config = options[:config] || 'Release'
        packages.each do |pkg|
          # El paquete para el IDE debe estar compilado para Win32
          search_pattern = (PRJ_IMPORTS + idever + 'Win32' + '{Debug,Release}' + 'bin' + pkg)
          avaiable_files = Pathname.glob(search_pattern).inject({}) do |mapped, p|
            mapped[p.dirname.parent.basename.to_s] = p
            mapped
          end
          avaible_configs = avaiable_files.keys
          use_config = (avaible_configs.include?(prefer_config) ? prefer_config : avaible_configs.first)
          pkg = avaiable_files[use_config]
          if pkg
            register(idever, pkg)
            puts "IDE library #{pkg.basename} (#{use_config}) installed"
          end
        end
      end

      def lib_tag
          "#{libname}-#{libver}"
      end

      def proccess
        raise "import's source undefined" unless @source
        block = @block
        configs.each do |config|
          cfg_segment = config.strip
          cfg_segment = "-#{cfg_segment}" unless cfg_segment.empty?
          lib_file = "#{lib_tag}-#{idever}#{cfg_segment}.zip"
          vendor_files = []
          destination = DVM_IMPORTS + idever

          exist = (cfg_segment.empty? ? (destination + lib_tag).exist? : (destination + lib_tag + cfg_segment).exist?)
          puts "\n#{exist ? '(exist) ':''}Importing #{lib_file} to #{destination.win}"
          unless exist
            if zip_file = download(source, lib_file)
              unzip(zip_file, destination) unless defined? Ocra
            end
          end
          vendorize(get_vendor_files) unless defined? Ocra
        end
        instance_eval(&block) if block
      end

      def get_vendor_files
        Pathname.glob(DVM_IMPORTS + idever + lib_tag + 'out/**/{Debug,Release}/{bin,lib}/*.*')
      end

      def vendorize(files)
        pb = ProgressBar.create(:total =>  files.size, title: '  %9s ->' % 'vendorize', format: "%t %J%% %E %B")
        files.each do |file|
          route = file.relative_path_from(DVM_IMPORTS + idever + lib_tag + 'out')
          install_vendor(PRJ_IMPORTS + route, file)
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

      def install_in_vendor?(fname)
        fname.fnmatch?('*/*/{bin,lib}/*', File::FNM_EXTGLOB + File::FNM_CASEFOLD) &&
        !fname.fnmatch?('*/{IDEServices.prj_paths[:samples], IDEServices.prj_paths[:test]}/{bin,lib}/*', File::FNM_EXTGLOB + File::FNM_CASEFOLD)
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
        start = lambda { |length| pb = ProgressBar.create(total: length, title: '  %9s ->' % 'download', format: "%t %J%% %E %B") }
        progress = lambda {|s| pb.progress = s; pb.refresh}

        begin
          start.call(full_url.size)
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
            unless f_path.directory?
              f_path.dirname.mkpath
              pb.increment
              f.extract(f_path) unless f_path.exist?
              yield f_path if block_given?
            end
          end
        end
        pb.finish
      end
    end
  end
end
