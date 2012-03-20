require 'open-uri'
require 'progressbar'

module	::Delphivm
	module DSL
		PATH_TO_VENDOR = ROOT + 'vendor'
		PATH_TO_VENDOR_CACHE = PATH_TO_VENDOR + 'cache'
		PATH_TO_VENDOR_IMPORTS = PATH_TO_VENDOR + 'imports'
	
		extend self
	
		def uses(path_to_file)
			source = File.read(path_to_file)
			class_eval(source, path_to_file, 1)
		end
		
		def idever(value = nil)
			@idever = value if value
			@idever
		end
		
		def source(value = nil)
			@source = value if value
			@source
		end
		
		def import(libname, libver, options={})
		  configs = options[:config]
			configs ||= 'Release'
			configs = ['Release', 'Debug'] if configs == '*'
			configs = [configs] unless configs.is_a?Array
			configs.each do |config|
				lib_file = "#{libname}-#{libver}-#{idever}-#{config}.zip"
				source_uri = source
				result = download(source_uri, PATH_TO_VENDOR_CACHE, lib_file)
				path_to_lib = PATH_TO_VENDOR_CACHE + lib_file
				unzip(path_to_lib, PATH_TO_VENDOR_IMPORTS) if result
			end
		end
		
	private
	
  	def download(source_uri, dowonlad_root_path, file_name)
			full_url = source_uri + '/' + file_name
			to_here = dowonlad_root_path + file_name
		  pb = nil
			puts "Downloading: #{full_url}"
			start = lambda do |length, hint=''| 
				pb = ProgressBar.new("#{file_name}", length);	
				pb.instance_variable_set "@title_width", file_name.length + 2
				pb.format =  "\s\s%-s #{hint} %3d%% %s %s"
				pb.clear
				pb.send :show
			end

    	progress = lambda {|s| pb.set(s)}

			if Pathname(to_here).exist?
				start.call(0, "(cached)")
			else
				open(to_here, "wb") do |wfile|	
				  begin
						content = open(full_url, content_length_proc: start, progress_proc: progress).read
						wfile.write(content)
					rescue Exception => e
						puts e
						return false
					end
				end
			end
			return true
		ensure
			pb.finish if pb
		end

		def unzip(file, destination)
			Zip::ZipFile.open(file) do |zip_file|
				pb = ProgressBar.new("", zip_file.size)
				pb.format =  "\s\s\s\sextracting: %3d%% %s file: %-34s"
				pb.format_arguments = [:percentage, :bar, :title]
				zip_file.each do |f|
					f_path = destination + f.name
					f_path.dirname.mkpath
					pb.instance_variable_set "@title", "#{f_path.basename}"
					pb.inc
					Pathname(f_path).delete if File.exist?(f_path)
					zip_file.extract(f, f_path) 
			 	end
				pb.finish
			end
		end
	end
	
	class Vendor < Thor
		namespace :vendor
		desc "install", "install vendor imports"
		def import
			prepare
			silence_warnings{DSL.uses(File.join(ROOT, 'vendor', 'vendor.dvm'))}
		end
		desc "clean", "Clean imports. Use -c (--cache) to also clean downloads cache"
		method_option :cache,  type: :boolean, aliases: '-c', default: false, desc: "also clean cache"
		def clean
			prepare
		  DSL::PATH_TO_VENDOR_CACHE.rmtree if options.cache?
		  DSL::PATH_TO_VENDOR_IMPORTS.rmtree
			prepare
		end
	private
		def prepare
			DSL::PATH_TO_VENDOR_CACHE.mkpath
			DSL::PATH_TO_VENDOR_IMPORTS.mkpath
		end	
	end
	
	class Project < Thor
		namespace :prj
    SHIP_FILE = "#{TARGET}-#{TARGET.VERSION.tag}"

    desc "idevers", "current used IDE versions"
		def idevers
			puts get_idevers.join("\n")
		end

		desc  "clean", "clean #{SHIP_FILE} products"
		method_option :config,  type: :array, aliases: '-c', default: 'Debug', desc: "use IDE config(s): Debug, Release, etc"
		def clean
			get_idevers.each do |idever|
				ide = IDEServices.new(idever, ROOT)
				configs = [options[:config]].flatten
				configs.each do |cfg|
					ide.msbuild(cfg, 'Clean')
				end
			end
		end	
		desc  "make", "make #{SHIP_FILE} products"
		method_option :config,  type: :array, aliases: '-c', default: 'Debug', desc: "use IDE config(s): Debug, Release, etc"
		def make
			get_idevers.each do |idever|
				ide = IDEServices.new(idever, ROOT)
				configs = [options[:config]].flatten
				configs.each do |cfg|
					ide.msbuild(cfg, 'Make')
				end
			end
		end

		desc  "build", "build #{SHIP_FILE} products"
		method_option :config,  type: :array, aliases: '-c', default: 'Debug', desc: "use IDE config(s): Debug, Release, etc"
		def build
			get_idevers.each do |idever|
				ide = IDEServices.new(idever, ROOT)
				configs = [options[:config]].flatten
				configs.each do |cfg|
					ide.msbuild(cfg, 'Build')
				end
			end
		end

		desc  "ship", "create ship file #{SHIP_FILE}.zip file"
		method_option :config,  type: :array, aliases: '-c', default: 'Debug', desc: "use build config(s): Debug, Release, etc"
		def ship
			invoke :build
			get_idevers.each do |idever|
				ide = IDEServices.new(idever, ROOT)
				configs = [options[:config]].flatten
				configs.each do |cfg|
					build_ship(idever, cfg)
				end
			end
		end
		
		desc "start IDEVER  ", "start IDE IDEVER"
		def start(idever)
			ide = IDEServices.new(idever, ROOT)
			ide.start 
		end
		
	private

		def get_idevers
			ROOT.glob('**/*.groupproj').map {|f| f.dirname.basename.to_s.split('-')[0]}
		end

		def build_ship(idever, config)
			zip_fname = ROOT + 'ship' + "#{SHIP_FILE}-#{idever}-#{config}.zip"
			zip_fname.dirname.mkpath
			zip_base_path = ROOT + 'out' + idever + config
			zip_fname.delete if zip_fname.exist? 
			puts "Ship file " + zip_fname.to_s
			Zip::ZipFile.open(zip_fname, Zip::ZipFile::CREATE) do |zipfile|
				Pathname.glob((zip_base_path + '**' + '*.*').to_s).each do |source_file|
					zip_entry = Pathname(config) + source_file.relative_path_from(zip_base_path)
					zipfile.get_output_stream(zip_entry) { |f| f.puts source_file.read(:mode => "rb") }
				end
			end    
		end
	end
end