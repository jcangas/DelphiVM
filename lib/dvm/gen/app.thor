require 'securerandom'
require 'delphivm/generator'


class Delphivm::Gen

	class App < Thor::Group
		include Generator

		argument :name, type: :string, desc: "app name to be executed"
		class_option :samples, type: :boolean, default: true, desc: "include samples"
		class_option :tests, type: :boolean, default: true, desc: "include tests"
		class_option :idever, type: :string, default: 'D170', desc: "IDE version"

		desc "Generate app structure in current dir"		
	 
		def execute
			self.class.output_folder = name.snake_case
			do_folder_template self.class.output_folder
		 	do_execute
			do_invoke Dproj, [self.name], idever: self.options[:idever], template: 'src'
  		end

		invoke_from_option :samples do |klass|
			do_invoke klass, ['Sample1'], idever: self.options[:idever]
		end
		invoke_from_option :tests do |klass|
			do_invoke klass, ['Test1'], idever: self.options[:idever]
		end
				
	private
		def self.prepare_for_invocation(key, name)
			case name
			when Symbol, String
				Gen.const_get(name.to_s.camelize)
			else
				name
			end
		end
	end

	class Samples < Thor::Group
		include Generator

		argument :name, type: :string, required: false, desc: "name for sample project to be executed"
		class_option :idever, type: :string, desc: "IDE version"

		desc "Generate samples structure in current dir"		

		def execute
			do_execute
			do_invoke Dproj, [self.name], idever: self.options[:idever], template: 'sample'
		end
	end

	class Tests < Thor::Group
		include Generator

		argument :name
		desc "Generate tests structure in current dir"		

		def execute
			do_execute
			do_invoke Dproj, [self.name], idever: self.options[:idever], template: 'test'
		end
	end

	class Dproj < Thor::Group
		include Generator

		argument :name, type: :string, required: false, desc: "name for project to be executed"

		desc "Generate delphi project"		

		class_option :template, aliases: '-t', type: :string, desc: "project template name"					
		class_option :idever, type: :string, desc: "IDE version"
		def execute
			self.class.subtemplate = self.options[:template]
			do_execute
			# forgett ithis invocation in order to  several invocations
			_shared_configuration[:invocations].delete self.class 
		end
	end
end
