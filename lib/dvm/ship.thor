require File.dirname(__FILE__) +  '/ship/group'

class Ship < Thor
	include Thor::Actions

	ShipGroup = ::Ship::FileSet #escape Thor sandbox

	desc  "clean IDE", "remove ship file(s) #{APP_ID}-XXX.zip"
	def clean
		ides_in_prj.each do |idever|
			do_clean(idever.to_s)
		end
	end

	desc "make", "make ship file(s) #{APP_ID}-XXX.zip"
	def make
		ides_in_prj.each do |idever|
			do_make(idever.to_s)
		end
	end

	desc "build", "build ship file(s) #{APP_ID}-XXX.zip"
	def build
		ides_in_prj.each do |idever|
			do_build(idever.to_s)
		end
	end

private
	def ides_in_prj
		IDEServices.ides_in_prj
	end

	def get_zip_name(idever)
		ROOT + 'ship' + "#{APP_ID}-#{idever}.zip"
	end
	
	def do_clean(idever)
		remove_file get_zip_name(idever)
	end

	def do_make(idever)
		zip_fname = get_zip_name(idever)
		empty_directory zip_fname.dirname
	
		groups = [
		ShipGroup.new(:binary, 'out/' + idever),
		ShipGroup.new(:source_resources, 'src', '**{.*,}/*.{dfm,fmx,res,dcr}', false),
		ShipGroup.new(:source, 'src'),
		ShipGroup.new(:source, '.', '*.*', false),
		ShipGroup.new(:documentation, 'doc'),
		ShipGroup.new(:samples, 'samples'),
		ShipGroup.new(:test, 'test')
		]

		platform_lib_paths = (ROOT + 'out' + idever + '**/lib/').glob.map{|p| p.relative_path_from p.parent.parent.parent}
		ship_dest = {
			binary: [Pathname('.')],
			source_resources: platform_lib_paths,
			source: [Pathname('src') + APP_ID],
			documentation: [Pathname('doc') + APP_ID],
			samples: [Pathname('samples') + APP_ID],
			test: [Pathname('test') + APP_ID]
		}
		ignore_files = ['*.local', '*.~*', '*.identcache']
		say_status(:create, zip_fname.relative_path_from(ROOT))	
		Zip::ZipFile.open(zip_fname, Zip::ZipFile::CREATE) do |zipfile|
			title = ''
			groups.each do |group|
				if title != new_title = group.name.to_s.camelize(' ')
					title = new_title
					say_status("add", "#{title} files", :yellow)
				end
				group.each do |file, origin_path|
					next if ignore_files.any?{|pattern| file.fnmatch?(pattern)}
					ship_dest[group.name].each do |dest|
						zip_entry = dest + file
						zipfile.get_output_stream(zip_entry) { |f| f.write origin_path.binread }
					end
				end
			end
		end
	end

	def do_build(idever)
		do_clean(idever)
		do_make(idever)		
	end
end