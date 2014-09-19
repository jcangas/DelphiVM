	
class Project < BuildTarget
	namespace :prj

	PRODUCT_ID = "#{::Delphivm::APPMODULE}-#{::Delphivm::APPMODULE.VERSION.tag}"

	desc  "clean", "clean #{APP_ID} products", :for => :clean
	desc  "make", "make #{APP_ID} products", :for => :make
	desc  "build", "build #{APP_ID} products", :for => :build

protected

	def do_clean(idetag, cfg)
		ide = IDEServices.new(idetag, ROOT)
		ide.call_build_tool('Clean', cfg)
	end

	def do_make(idetag, cfg)
		ide = IDEServices.new(idetag, ROOT)
		ide.call_build_tool('Make', cfg)
	end

	def do_build(idetag, cfg)
		ide = IDEServices.new(idetag, ROOT)
		ide.call_build_tool('Build', cfg)
	end

private

end
