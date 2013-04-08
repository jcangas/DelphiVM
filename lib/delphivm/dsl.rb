# encoding: UTF-8
class Delphivm

  module DSL
    extend self
     
    def uses(path_to_file)
      source = File.read(path_to_file)
      class_eval(source, path_to_file, 1)
    end
    
    def idever(value = nil, &block)
      return @idever unless value
      @idever = value
      class_eval(&block)
    end
    
    def source(value = nil)
      return @source unless value
      @source = value
    end
    
    def import(libname, libver, options={})
      configs = options[:config]
      configs ||= ''
      configs = ['Release', 'Debug'] if configs == '*'
      configs = [configs] unless configs.is_a?Array
      source_uri = source
      configs.each do |config|
        cfg_segment = config.strip
        cfg_segment = "-#{cfg_segment}" unless cfg_segment.empty?
        lib_file = "#{libname}-#{libver}-#{idever}#{cfg_segment}.zip"
        result = download(source_uri, PATH_TO_VENDOR_CACHE, lib_file)
        path_to_lib = PATH_TO_VENDOR_CACHE + lib_file
        unzip(path_to_lib, PATH_TO_VENDOR_IMPORTS + idever) if result
      end
    end
    
  private
  
    def download(source_uri, dowonlad_root_path, file_name)
      full_url = source_uri + '/' + file_name
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