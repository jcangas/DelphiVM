
class Gen < Thor

end

module Generator
	TEMPLATE_ROOT = GEM_ROOT + Pathname('templates/delphi')

	def self.included(base) #:nodoc:
		base.send :include, Thor::Actions
		base.add_runtime_options!
 		base.extend ClassMethods
 		
	end

	module ClassMethods
		attr_accessor :subtemplate
		attr_accessor :output_folder
		
		def get_app_name
			@app_name = output_folder.basename.to_s.camelize
		end

		def desc(msg)
	 		command = name.split(':')[-1].downcase
	 		args = self.arguments.map {|arg| arg.usage }.join(' ')
	 		Gen.register(self, command, command + ' ' + args, msg)
	 		# hide from  list
	 		namespace('gen:' + command)
	 		group('gen')
	 		super
		end

		def template_subfolder
			[self.name.split('::')[-1].snake_case, subtemplate].compact.join('-') + '.tt'
		end

		def output_folder
			@output_folder ||= ROOT
		end

		def output_folder=(value)
			@output_folder = Pathname(value.to_s)
		end

		def source_root
			TEMPLATE_ROOT + self.template_subfolder
		end

	end
	
	def method_missing(name, *args, &block)
		return self.options[name.to_s] if self.options.has_key?(name.to_s)
		super
	end

	def do_create_subfolder
		empty_directory self.class.output_folder
	end

	def do_generate
		self.class.source_root.glob('**/*') do |f|
			params = {app_name: self.class.get_app_name}
			options.each do |k, v|
				params[k.to_sym] = v
			end
			self.class.arguments.each do |arg|
				params[arg.name.to_sym] = self.send(arg.name)
			end
			
			source = f.relative_path_from(self.class.source_root)
			target = self.class.output_folder + source
			target = Pathname(target.to_s % params)
			if f.directory?
				empty_directory(target)
			else
				begin
					template(source, target.dirname + target.basename('.tt'))
				rescue Exception => e
					say "task #{self.class.namespace} proccessing template #{source}", :red
					say "ERROR: #{e.message}", :red
					say "avaiable params:\n", :red
					print_table(params.inject({}){|r,p| r[":#{p[0]} => "] = p[1];r}.to_a)
					raise ""
				end
			end
		end
	end

	def do_invoke(*names, &block)
		klass = names[0]
		klass.output_folder = self.class.output_folder
		invoke(*names, &block)
	end
end


	class App < Thor::Group
		include Generator

		argument :name, type: :string, desc: "app name to be generated"
		class_option :samples, type: :boolean, default: true, desc: "include samples"
		class_option :tests, type: :boolean, default: true, desc: "include tests"
		class_option :idever, type: :string, default: 'D170', desc: "IDE version"

		desc "Generate app structure in current dir"		
						
		def generate
			self.class.output_folder = name.snake_case
			do_create_subfolder
		 	do_generate
		end

		invoke_from_option :samples do |klass|
			do_invoke klass, ['Sample1'], idever: self.options[:idever]
		end
		invoke_from_option :tests do |klass|
			do_invoke klass, ['Test1']
		end
				
	private
		def self.prepare_for_invocation(key, name)
			case name
			when Symbol, String
				const_get(name.to_s.camelize)
			else
				name
			end
		end
	end

class App
	class Samples < Thor::Group
		include Generator

		argument :name, type: :string, required: false, desc: "name for sample project to be generated"
		class_option :idever, type: :string, desc: "IDE version"

		desc "Generate samples structure in current dir"		

		def generate
			do_generate
			do_invoke Dproj, [self.name], idever: self.options[:idever], template: 'sample'
		end
	end

	class Tests < Thor::Group
		include Generator

		argument :name
		desc "Generate tests structure in current dir"		

		def generate
			do_generate
		end
	end

	class Dproj < Thor::Group
		include Generator

		argument :name, type: :string, required: false, desc: "name for project to be generated"

		desc "Generate delphi project"		

		class_option :template, aliases: '-t', type: :string, desc: "project template name"					
		class_option :idever, type: :string, desc: "IDE version"
		def generate
			self.class.subtemplate = self.options[:template]
			do_generate
		end
	end
end
