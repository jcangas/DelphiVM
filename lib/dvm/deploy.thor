class Deploy < BuildTarget

	self.configure do |cfg|
		cfg.deploy_to_bin! false
	end

	def self.deploy_files_for(options)
		return []
	end

	method_option :env, type: :string, aliases: '-e', default: 'deve', desc: "deploy run [ENV]", for: :clean
	method_option :env, type: :string, aliases: '-e', default: 'deve', desc: "deploy run [ENV]", for: :make
	method_option :env, type: :string, aliases: '-e', default: 'deve', desc: "deploy run [ENV]", for: :build

protected

	def do_make(idetag, cfg)
		deploy_environment(idetag, cfg)
		deploy_files(idetag, cfg)
	end

	def deploy_files(idetag, cfg)

        options = {
        	idetag: idetag,
            ide_root_path:  IDEServices.new(idetag).ide_root_path,
            import_path: PRJ_IMPORTS + idetag,
            out_path: out_path + idetag
         }

		say "deploying files"
		IDEServices.platforms_in_prj(idetag).each do |platform|
			IDEServices.configs_in_prj(idetag).each do |config|
	            options[:platform] = platform
	            options[:config] = config
	            self.class.deploy_files_for(options).each { |source, destination|  deploy_product(source, destination)	}
			end
		end
	end

	def deploy_environment(idetag, cfg)
	  say "deploying environment #{options["env"]}"
    source_env_path = self.send("runenv_#{options["env"]}_path")
  	source_env_path.glob('**') do |source|
			environment_target_path.each do |destination|
				deploy_product(source, destination + source.relative_path_from(source_env_path))
			end
		end
	end

	def deploy_product(source, destination)
		if source.exist?
			catch_product(destination) do |product|
		    	get(source.to_s, product, force: true) if source.file?
		    	directory(source, product) if source.directory?
		    end
		end
	end

	def environment_target_path
		result = []
		if self.class.configure.deploy_to_bin
			IDEServices.platforms_in_prj(idetag).each do |platform|
				IDEServices.configs_in_prj(idetag).each do |config|
					result << self.out_path + idetag + platform + config + 'bin'
				end
			end
		else
			result << self.out_path
		end
		result
	end

end
