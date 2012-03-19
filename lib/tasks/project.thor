require 'open-uri'
require 'progressbar'

module	::Delphivm
	module Loader
  	def self.download(full_url, to_here)
		  pb = nil
			start = lambda {|length| pb = ProgressBar.new(File.basename(to_here), length) }
    	progress = lambda {|s| pb.set(s)}
			open(to_here, "wb") do |wfile|
				wfile.write(open(full_url, content_length_proc: start, progress_proc: progress).read)
			end
			pb.finish
		end
		
		def self.install(libname, libver, options={})
			target = "#{libname}-#{libver}-#{options[:idever]}-#{options[:config]}.zip"
			download( "#{options[:source]}/#{target}", File.join(ROOT, 'vendor', target))
   	end
	end
	
	class Vendor < Thor
		namespace :vendor
		desc "install", "install vendor required libs"
		def install
			path = File.join(ROOT, 'vendor', 'vendor.dvm')
			content = File.binread(path)
			Loader.class_eval(content, path)
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