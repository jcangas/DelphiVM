
class Project < BuildTarget
	namespace :prj

	desc  "clean", "clean #{APP_ID} products", :for => :clean
	desc  "make", "make #{APP_ID} products", :for => :make
	desc  "build", "build #{APP_ID} products", :for => :build

	method_option :group, type: :string, aliases: '-g', default: self.configuration.build_args, desc: "Use BuildGroup", for: :clean
	method_option :group, type: :string, aliases: '-g', default: self.configuration.build_args, desc: "Use BuildGroup", for: :make
	method_option :group, type: :string, aliases: '-g', default: self.configuration.build_args, desc: "Use BuildGroup", for: :build

	desc 'reset', 'erase prj out'
	def reset
		do_reset
	end

protected

	def do_reset
		remove_dir(root_out_path)
	end

	def do_clean(idetag, cfg)
		do_build_action(idetag, cfg, 'Clean')
	end

	def do_make(idetag, cfg)
		do_build_action(idetag, cfg, 'Make')
	end

	def do_build(idetag, cfg)
		do_build_action(idetag, cfg, 'Build')
	end

private

 def do_build_action(idetag, cfg, action)
	ide = IDEServices.new(idetag, PRJ_ROOT)
	cfg = {} unless cfg
	cfg['BuildGroup'] = options[:group] if options.group?
	ide.call_build_tool(action, cfg)
 end

end
