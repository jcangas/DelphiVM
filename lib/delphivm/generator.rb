class Delphivm

	module Generator
		TEMPLATE_ROOT = GEM_ROOT + Pathname('templates/delphi')

		def self.included(base) #:nodoc:
			base.send :include, Thor::Actions
			base.add_runtime_options!
			base.extend ClassMethods
		end

		module ClassMethods
			def subtemplate
				@subtemplate
			end

			def subtemplate=(value)
				@subtemplate = value
			end
			
			def get_app_name
				@app_name = output_folder.basename.to_s.camelize
			end

			def desc(*msg)
				if msg.size==1
					command = name.split(':')[-1].downcase
					args = self.arguments.map {|arg| arg.usage }.join(' ')
					# # hide from  thor standard list
					group(' ')
					Gen.register(self, command, command + ' ' + args, *msg)
				end
				super *msg
			end

			def template_subfolder
				subpath = (subtemplate.to_s.empty? ? '' : '/' + subtemplate.to_s)
				@template_subfolder = self.name.split('::')[-1].snake_case + subpath + '.tt'
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
			binding_params.has_key?(name) ? binding_params[name] : super
		end

		def do_folder_template(folder)
			empty_directory folder
		end

		def do_file_template(source, target)
			template(source, target.dirname + target.basename('.tt'))
			rescue Exception => e
			say "task #{self.class.namespace} proccessing template #{source}", :red
			say "ERROR: #{e.message}", :red
			say "avaiable params:\n", :red
			print_table(binding_params.inject({}){|r,p| r[":#{p[0]} => "] = p[1];r}.to_a)
			raise ""
		end

		def skip_template_item?(item, directory)
			if directory && item.to_s =~ /@(.+)/
				($1 != binding_params[:idever])
			else
				false
			end
		end

		def do_execute
			self.class.source_root.glob('**/*') do |f|
				source = f.relative_path_from(self.class.source_root)
				target = self.class.output_folder + source
			
				next if skip_template_item?(source, f.directory?)
						
				target = Pathname(target.to_s.gsub('@','') % binding_params)
				if f.directory?
					do_folder_template target
				else
					do_file_template(source, target)
				end
			end
		end

		def binding_params
				return @binding_params if @binding_params
				@binding_params = {app_name: self.class.get_app_name}
				options.each do |k, v|
					@binding_params[k.to_sym] = v
				end
				self.class.arguments.each do |arg|
					@binding_params[arg.name.to_sym] = self.send(arg.name)
				end
				@binding_params	
		end

		def do_invoke(*names, &block)
			propagate_thor_runtime_options(*names)
			klass = names[0]
			klass.output_folder = self.class.output_folder
			invoke(*names, &block)
		end

		def propagate_thor_runtime_options(*names)
			names[2] ||= {} # ensure we have options hash
			%w(force pretend quiet skip).each do |rt_opt|
				names[2][rt_opt] = options[rt_opt] if options.has_key?(rt_opt)
			end
		end
	end

end