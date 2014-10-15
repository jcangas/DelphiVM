
class Ship < DvmTask
	require File.dirname(__FILE__) +  '/ship/group'

	ShipGroup = ::Ship::FileSet #prefix :: allow escape Thor sandbox

	self.configure do |cfg|
		cfg.ship_groups!  %w(binary libs PRJ_ROOT hpp source_resources source documentation samples test)
		cfg.publish_to! false
	end

	desc "clean IDE", "remove ship file(s) #{APP_ID}-IDE.zip"
	def clean
		ides_in_prj.each do |idever|
			do_clean(idever.to_s)
		end
	end

	desc "make", "make ship file(s) #{APP_ID}-IDE.zip"
    method_option :groups,  type: :array, aliases: '-g', default: configuration.ship_groups, desc: "groups to include"
	def make
		ides_in_prj.each do |idever|
			do_make(idever.to_s)
		end
	end

	desc "build", "build ship file(s) #{APP_ID}-IDE.zip"
    method_option :groups,  type: :array, aliases: '-g', default: configuration.ship_groups, desc: "groups to include"
	def build
		ides_in_prj.each do |idever|
			do_build(idever.to_s)
		end
	end

protected
	def get_zip_name(idever)
		PRJ_ROOT + 'ship' + "#{APP_ID}-#{idever}.zip"
	end

	def ides_in_prj
		IDEServices.ides_in_prj
	end

	def do_clean(idever)
		remove_file get_zip_name(idever)
	end

	def publish(idever)
		target = self.class.configuration.publish_to
		return unless target
		say "publishing #{target}"
		target = Pathname(target) + get_zip_name(idever).basename
		get(get_zip_name(idever).to_s, target, force: true)
	end

	def do_make(idever)
		buil_zip(idever)
		publish(idever)
	end

	def buil_zip(idever)
		zip_fname = get_zip_name(idever)
		empty_directory zip_fname.dirname

		groups = [
			ShipGroup.new(:binary, 'out/' + idever, '*/*/bin/**{.*,}/*.*'),
			ShipGroup.new(:libs, 'out/' + idever, '*/*/lib/**{.*,}/*.*'),
			ShipGroup.new(:hpp, 'out/' + idever, '**{.*,}/*.{h,hpp}'),
			ShipGroup.new(:source_resources, IDEServices.prj_paths[:src], '**{.*,}/*.{dfm,fmx,res,dcr}', false),
			ShipGroup.new(:source, IDEServices.prj_paths[:src]),
			ShipGroup.new(:PRJ_ROOT, '.', '*.*', false),
			ShipGroup.new(:documentation, IDEServices.prj_paths[:doc]),
			ShipGroup.new(:samples, IDEServices.prj_paths[:samples]),
			ShipGroup.new(:test, IDEServices.prj_paths[:test])
		]

		platform_lib_paths = (PRJ_ROOT + 'out' + idever + '*/*/lib/').glob.map{|p| p.relative_path_from p.parent.parent.parent}
		ship_dest = {
			binary: [Pathname('.')],
			libs: [Pathname('.')],
			hpp: [Pathname('.')],
			source_resources: platform_lib_paths,
			source: [Pathname(APP_ID) + IDEServices.prj_paths[:src]],
			PRJ_ROOT: [Pathname(APP_ID)],
			documentation: [APP_ID + IDEServices.prj_paths[:doc]],
			samples: [Pathname(APP_ID) + IDEServices.prj_paths[:samples]],
			test: [Pathname(APP_ID) + IDEServices.prj_paths[:test]]
		}

		ignore_files = ['*.local', '*.~*', '*.identcache']
		say_status(:create, zip_fname.relative_path_from(PRJ_ROOT))

		valid_groups = options[:groups]
		ziped_files = []
		Zip::File.open(zip_fname, Zip::File::CREATE) do |zipfile|
			title = ''
			groups.each do |group|
				next unless valid_groups.include?(group.name.to_s)
				if title != new_title = group.name.to_s.camelize(' ')
					title = new_title
					say_status("add", "#{title} files", :yellow)
				end
				group.each do |file, origin_path|
					next if ignore_files.any?{|pattern| file.fnmatch?(pattern)}
					ship_dest[group.name].each do |dest|
						zip_entry = dest + file
						zipfile.add(zip_entry, origin_path) unless ziped_files.include?(zip_entry)
						ziped_files << zip_entry
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
