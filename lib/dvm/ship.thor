
class Ship < BuildTarget
	require File.dirname(__FILE__) +  '/ship/group'

	self.configure do |cfg|
		cfg.ship_groups! %w(source doc samples test)
		cfg.publish_to! false
	end

	desc  "clean", "remove ship file #{APP_ID}-#{IDEServices.default_ide}.zip", :for => :clean
	desc  "make", "make ship file(s) #{APP_ID}-#{IDEServices.default_ide}.zip", :for => :make
	desc  "build", "build ship file(s) #{APP_ID}-#{IDEServices.default_ide}.zip", :for => :build
  
  method_option :groups,  type: :array, aliases: '-g', default: configuration.ship_groups, desc: "use groups: bin lib source doc samples test", for: :make
  method_option :groups,  type: :array, aliases: '-g', default: configuration.ship_groups, desc: "use groups: bin lib source doc samples test", for: :build
  
protected
	def get_zip_name(idetag)
		Pathname('ship') + spec.get_zip_name(idetag)
	end

	def ides_in_prj
		IDEServices.ides_in_prj
	end

	def publish(idetag)
		target = self.class.configuration.publish_to
		return unless target
		target = (Pathname(target) + get_zip_name(idetag).basename).to_s
		target.gsub!(/\$\((\w+)\)/){|m| ENV[$1]}
		say_status "publish to", target
		get(get_zip_name(idetag).to_s, target, force: true, verbose: false)
	end

	def do_clean(idetag, cfg)
		remove_file get_zip_name(idetag)
	end

	def do_make(idetag, cfg)
		buil_zip(idetag)
		publish(idetag)
	end

	def buil_zip(idetag)
		zipfname = get_zip_name(idetag)
		remove_file(zipfname.to_s, verbose: false)
		say "create ship file for #{idetag}"
		pb = ProgressBar.create(title: '  %10s ->' % 'collect files', format: "%t %J%% %E %B")
		start = lambda{|size| pb.total = size}
		progress = lambda{|file| pb.increment}
		zipping = lambda{pb.finish; say "     zipping ..."}
		done = lambda{ say "     done!"}
		spec.build(idetag, self.class.configuration.ship_groups, outdir: 'ship', start: start, progress: progress, zipping: zipping, done: done)
	end

	def spec
		@spec ||= ::Ship::Spec.new do |s|
			s.name = Delphivm::APPMODULE.name
			s.version = Delphivm::APPMODULE.VERSION.tag
			s.ignore_files(['**/*.~*', '**/*.bak', '**/*.local', '**/*.identcache' ,'*.log', '.DS_Store'])
			s.bin_files("out/%{idetag}/*/*/bin/**{.*,}/*.*")
			s.lib_files("out/%{idetag}/*/{Debug,Release}/lib/*.*")
			s.source_files(["src/**/*.*", "*.*"])
			s.sample_files("samples/**/*.*")
			s.test_files("test/**/*.*")
			s.doc_files("doc/**/*.*")
		end
	end

end
