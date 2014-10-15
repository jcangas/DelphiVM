
class Project < BuildTarget
	namespace :prj

	self.configure do |cfg|
		cfg.paths_map!({src: 'src', doc: 'doc', samples: 'samples', test: 'test'})
		cfg.build_args!({BuildGroup: 'All'})
	end

	IDEServices.prj_paths(self.configure.paths_map.to_h)

	PRODUCT_ID = "#{::Delphivm::APPMODULE}-#{::Delphivm::APPMODULE.VERSION.tag}"

	desc  "clean", "clean #{APP_ID} products", :for => :clean
	desc  "make", "make #{APP_ID} products", :for => :make
	desc  "build", "build #{APP_ID} products", :for => :build

protected

	def do_clean(idetag, cfg)
		ide = IDEServices.new(idetag, PRJ_ROOT)
		ide.call_build_tool('Clean', cfg)
	end

	def do_make(idetag, cfg)
		ide = IDEServices.new(idetag, PRJ_ROOT)
		ide.call_build_tool('Make', cfg)
	end

	def do_build(idetag, cfg)
		ide = IDEServices.new(idetag, PRJ_ROOT)
		ide.call_build_tool('Build', cfg)
	end

private

end
