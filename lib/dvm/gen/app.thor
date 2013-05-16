module Gen
	def self.template_root
		Pathname('templates/delphi')
	end
  
	module Wizard
		module Klass
			def template_subfolder
				self.name.split('::')[-1].downcase + '.tt'
			end

			def destination_subfolder(value = nil)
				return @destination_subfolder unless value
				@destination_subfolder = value				
			end

			def source_root
				GEM_ROOT + Gen.template_root + self.template_subfolder
			end

			def destination_root
				ROOT + destination_subfolder
			end
		end
		
		def do_generate
			self.class.source_root.glob('**/*') do |f|
				target = f.relative_path_from(self.class.source_root)
				if f.directory?
					empty_directory(target) 
				else
				 template(target, target.dirname + target.basename('.tt'))
				end
			end
		end
	end
	
	class App < Thor::Group
		include Thor::Actions
		extend Wizard::Klass
		include Wizard
		
		attr :app_root

		desc "Generate app structure in current dir"		
		# Define arguments and options
		argument :app_name

		class_option :sample, type: :boolean, default: true
						
		def create_prj_root
		 @app_root = Pathname(app_name)
		 self.class.destination_subfolder(@app_root)
		 empty_directory @app_root
		end
		 
		def generte
		  do_generate
		end

		invoke_from_option :sample do |klass|
			# invoke klass, ['sample1'], app_root: @app_root 
			invoke klass, ['sample1'] 
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
	
	class Sample < Thor::Group
		argument :app_name
		class_option :app_root, type: :string, hide: true, default: Delphivm::ROOT
		def greeting
			say "sample #{self.app_name} app_root: #{self.options[:app_root]}"
		end
	end
end


