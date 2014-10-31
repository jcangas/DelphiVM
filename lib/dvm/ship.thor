
class Ship < DvmTask
	require File.dirname(__FILE__) +  '/ship/group'

	self.configure do |cfg|
		cfg.ship_groups! %w(bin lib source doc samples test)
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
		Pathname('ship') + spec.get_zip_name(idever)
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
		say_status "publishing", target
		target = Pathname(target) + get_zip_name(idever).basename
		get(get_zip_name(idever).to_s, target, force: true, verbose: false)
	end

	def do_make(idever)
		buil_zip(idever)
		publish(idever)
	end

	def buil_zip(idever)
		zipfname = get_zip_name(idever)
		remove_file(zipfname.to_s, verbose: false)
		say "create ship file for #{idever}"
		pb = ProgressBar.create(title: '  %10s ->' % 'collect files', format: "%t %J%% %E %B")
		start = lambda{|size| pb.total = size}
		progress = lambda{|file| pb.increment}
		zipping = lambda{pb.finish; say "     zipping ..."}
		done = lambda{ say "     done!"}
		spec.build(idever, self.class.configuration.ship_groups, outdir: 'ship', start: start, progress: progress, zipping: zipping, done: done)
	end

	def spec
		@spec ||= ::Ship::Spec.new do |s|
			s.name = Delphivm::APPMODULE.name
			s.version = Delphivm::APPMODULE.VERSION.tag
			s.ignore_files(['**/*.~*', '**/*.bak', '**/*.local', '**/*.identcache' ,'*.log', '.DS_Store'])
			s.bin_files("out/%{idever}/*/*/bin/**{.*,}/*.*")
			s.lib_files("out/%{idever}/*/{Debug,Release}/lib/*.*")
			s.source_files(["src/**/*.*", "*.*"])
			s.sample_files("samples/**/*.*")
			s.test_files("test/**/*.*")
			s.doc_files("doc/**/*.*")
		end
	end

	def do_build(idever)
		do_clean(idever)
		do_make(idever)
	end

end
