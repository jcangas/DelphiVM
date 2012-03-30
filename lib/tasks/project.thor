
	
class Project < Thor

	SHIP_FILE = "#{TARGET}-#{TARGET.VERSION.tag}"

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
	method_option :config,  type: :array, aliases: '-c', default: 'Debug', desc: "use IDE config(s): Debug, Release, etc"
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
	
private

	def get_idevers
		IDEServices.ideused
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
