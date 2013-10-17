
class Delphivm
  module DSL
    def self.run_imports_dvm_script(path_to_file)
      puts path_to_file
      ImportScript.new(File.read(path_to_file), path_to_file)
    end

    class ImportScript < Object
      attr :idever

      def initialize(script, path_to_file)
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

      def import(libname, libver, options={}, &block)
        importer = Importer.new(self, libname, libver, options, &block)
      end      
    end

    class Importer
      attr :idever
      attr :configs

      def initialize(script, libname, libver, options={}, &block)
        source_uri = script.source
        @idever = script.idever
        @configs = options[:config]
        @configs ||= ''
        @configs = ['Release', 'Debug'] if configs == '*'
        @configs = [configs] unless configs.is_a?Array

        configs.each do |config|
          cfg_segment = config.strip
          cfg_segment = "-#{cfg_segment}" unless cfg_segment.empty?
          lib_file = "#{libname}-#{libver}-#{idever}#{cfg_segment}.zip"
          result = download(source_uri, PATH_TO_VENDOR_CACHE, lib_file)
          path_to_lib = PATH_TO_VENDOR_CACHE + lib_file
          unzip(path_to_lib, PATH_TO_VENDOR_IMPORTS + idever) if result        
        end
        instance_eval(&block) if block
      end

      private

      def ide_install(*packages)
        ide_prj = IDEServices.new(idever)
        options = packages.pop if packages.last.is_a? Hash
        options ||= {}

        prefer_config = options[:config]
        packages.each do |pkg| 
          # la trayectoria debe terminar en \idever\platform\config
          avaiable_files = Pathname.glob(PATH_TO_VENDOR_IMPORTS + idever + '**' + pkg).inject({}) do |mapped, p| 
            mapped[p.dirname.parent.basename.to_s] = p
            mapped
          end
          avaible_configs = avaiable_files.keys
          use_config = (avaible_configs.include?(prefer_config) ? prefer_config : avaible_configs.first)
          pkg = avaiable_files[use_config]
          if pkg
            puts "register IDE library #{pkg.basename} with config: #{use_config}"
            puts %x(reg add "#{ide_prj.pkg_regkey}" /v "#{pkg.win}" /d "#{ide_prj.prj_slug}" /f)
          end
        end
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

      def unzip(file, destination)
        Zip::ZipFile.open(file) do |zip_file|
          pb = ProgressBar.create(:total =>  zip_file.size, :format => "extracting %c/%C %B %t")
          zip_file.each do |f|
            f_path = destination + f.name
            next if Pathname(f_path).directory?
            f_path.dirname.mkpath
            pb.title = "#{f_path.basename}"
            Pathname(f_path).delete if File.exist?(f_path)
            zip_file.extract(f, f_path) 
          end
          pb.finish
        end
      end
    end
  end
end