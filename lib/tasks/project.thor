
	
class Project < BuildTarget

	SHIP_FILE = "#{TARGET}-#{TARGET.VERSION.tag}"

	desc  "clean", "clean #{SHIP_FILE} products", :for => :clean
	
	desc  "make", "make #{SHIP_FILE} products", :for => :make
	desc  "build", "build #{SHIP_FILE} products", :for => :build

	desc  "ship", "create ship file #{SHIP_FILE}.zip file"
	method_option :config,  type: :array, aliases: '-c', default: '', desc: "use IDE config(s): Debug, Release, etc"
	def ship
		get_idevers.each do |idever|
			ide = IDEServices.new(idever, ROOT)
			configs = [options[:config]].flatten
			configs.each do |cfg|
				build_ship(idever, cfg)
			end
		end
	end
	
protected

	def do_clean(idetag, cfg)
		ide = IDEServices.new(idetag, ROOT)
		ide.msbuild(cfg, 'Clean')
	end

	def do_make(idetag, cfg)
		ide = IDEServices.new(idetag, ROOT)
		ide.msbuild(cfg, 'Make')
	end

	def do_build(idetag, cfg)
		ide = IDEServices.new(idetag, ROOT)
		ide.msbuild(cfg, 'Build')
	end

private

	def get_idevers
		IDEServices.ideused
	end

	def build_ship(idever, config)
		cfg_segment = config.strip
		cfg_segment = "-#{cfg_segment}" unless cfg_segment.empty?
    
		zip_fname = ROOT + 'ship' + "#{SHIP_FILE}-#{idever}#{cfg_segment}.zip"
		zip_fname.dirname.mkpath
		zip_fname.delete if zip_fname.exist? 
		
		groups = [
			["output", ROOT + 'out' + idever + config, Pathname('.')],
			["source", ROOT + 'src', Pathname('src') + SHIP_FILE],
			["sample", ROOT + 'samples', Pathname('samples') + SHIP_FILE],
			["documentation", ROOT + 'doc', Pathname('doc') + SHIP_FILE]
		]
		puts "Ship file " + zip_fname.to_s
		Zip::ZipFile.open(zip_fname, Zip::ZipFile::CREATE) do |zipfile|
		  groups.each do |group|
				puts "Add #{group[0]} files"		
				Pathname.glob((group[1] + '**' + '*.*').to_s).each do |source_file|
					zip_entry = group[2] + source_file.relative_path_from(group[1])
					zipfile.get_output_stream(zip_entry) { |f| f.puts source_file.read(:mode => "rb") }
				end
			end
		end
	end
end
