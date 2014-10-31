
class Project < BuildTarget
	namespace :prj

	desc  "clean", "clean #{APP_ID} products", :for => :clean
	desc  "make", "make #{APP_ID} products", :for => :make
	desc  "build", "build #{APP_ID} products", :for => :build
	method_option :group, type: :string, aliases: '-g', default: self.configuration.build_args, desc: "BuildGroup", for: :build

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
		cfg = {} unless cfg
		cfg['BuildGroup'] = options[:group] if options.group?
		ide.call_build_tool('Build', cfg)
	end

private

end
