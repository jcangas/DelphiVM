
class Delphivm
  module DSL
    def self.run_imports_dvm_script(path_to_file, options = {})
      puts path_to_file
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

      def proccess
        block = @block
        configs.each do |config|
          cfg_segment = config.strip
          cfg_segment = "-#{cfg_segment}" unless cfg_segment.empty?
          lib_file = "#{libname}-#{libver}-#{idever}#{cfg_segment}.zip"
          result = download(source, PATH_TO_VENDOR_CACHE, lib_file)
          path_to_lib = PATH_TO_VENDOR_CACHE + lib_file
          unzip(path_to_lib, PATH_TO_VENDOR_IMPORTS + idever) if result
        end
        instance_eval(&block) if block
      end

      def ide_install(*packages)
        options = packages.pop if packages.last.is_a? Hash
        options ||= {}

        prefer_config = options[:config]
        packages.each do |pkg|
          # El paquete para el IDE debe estar compilado para Win32
          avaiable_files = Pathname.glob(PATH_TO_VENDOR_IMPORTS + idever + 'Win32' + '*' + 'bin' + pkg).inject({}) do |mapped, p|
            mapped[p.dirname.parent.basename.to_s] = p
            mapped
          end
          avaible_configs = avaiable_files.keys
          use_config = (avaible_configs.include?(prefer_config) ? prefer_config : avaible_configs.first)
          pkg = avaiable_files[use_config]
          register(idever, pkg) if pkg
        end
      end

      def register(idever, pkg)
        ide_prj = IDEServices.new(idever)
        puts "register IDE library #{pkg.win}"
        WinServices.reg_add(key: ide_prj.pkg_regkey, value: pkg.win, data: ide_prj.prj_slug, force: true)
      end

      def download(source_uri, dowonlad_root_path, file_name)
        full_url = Pathname(source_uri) + file_name
        to_here = dowonlad_root_path + file_name
        pb = nil
        puts "\nDownloading: #{full_url}"
        start = lambda do |length, hint=''|
          pb = ProgressBar.create(:title => "#{hint}", :format => "%t %E %w");
        end

        progress = lambda {|s| pb.progress = s; pb.refresh}

        if Pathname(to_here).exist?
          start.call(0, "(cached) ")
        else
          begin
            content = open(full_url, "rb", content_length_proc: start, progress_proc: progress).read
            File.open(to_here, "wb") do |wfile|
              wfile.write(content)
            end
          rescue Exception => e
            puts e
            Pathname(to_here).delete if File.exist?(to_here)
            return false
          end
        end
        return true
      ensure
          pb.finish if pb
      end

      def install_vendor(link, target)
        link.dirname.mkpath
        if @script.options.sym?
          WinServices.mklink(link: link.win, target: target.win)
        else
          FileUtils.cp(target, link)
        end
      end

      def unzip(file, destination)
        Zip::File.open(file) do |zip_file|
          pb = ProgressBar.create(:total =>  zip_file.size, :format => "%J%% %E %B")
          zip_file.each do |f|
            f_path = destination + f.name
            next if f_path.directory?
            f_path.dirname.mkpath
            pb.title =( "%30s" % "#{f_path.basename}")
            pb.increment
            f_path.delete if File.exist?(f_path)
            zip_file.extract(f, f_path)
            install_vendor(PATH_TO_VENDOR + 'imports' + idever + f.name, f_path) if Pathname(f.name).fnmatch?('*/*/{bin,lib}/*', File::FNM_EXTGLOB)
          end
          pb.finish
        end
      end
    end
  end
end
