class Deploy < BuildTarget

	self.configure do |cfg|
		cfg.deploy_to_bin! false
	end

	def self.deploy_imports_for(options)
		return []
	end

protected

	def do_make(idetag, cfg)
		deploy_environment(idetag, cfg)
		deploy_imports(idetag, cfg)
		deploy_other_files(idetag, cfg)
	end

	def deploy_imports(idetag, cfg)

    	ide_root_path = IDEServices.new(idetag).ide_root_path

		say "deploying imports"
		self.out_path.glob("#{idetag}/*/*/bin/") do |path_target|

            config = path_target.parent.basename
            platform =  path_target.parent.parent.basename
      
            import_path = vendor_imports_path + idetag
    
            options = {idetag: idetag, 
                 platform: platform, 
                 config: config, 
                 ide_root_path: ide_root_path, 
                 import_path: import_path,
                 out_path: out_path + idetag}
                 
  		    self.class.deploy_imports_for(options).each do |src_path, target_path|

                catch_product(target_path) do |product|
                    if src_path.exist?
                        get(src_path.to_s, product, force: true) if src_path.file?
            	       directory(src_path, product) if src_path.directory?
                    end
                end
            end
		end
	end

	def deploy_environment(idetag, cfg)
		say "deploying  environment"
		self.src_RunEnviroment_path.glob('*') do |path_source|
			environment_target_path.each do |path_target|
				catch_product(path_target + path_source.relative_path_from(src_RunEnviroment_path)) do |path_to_deploy|
					get(path_source.to_s, path_to_deploy) if path_source.file?
					directory(path_source, path_to_deploy) if path_source.directory?
				end
			end
		end
	end

	def deploy_other_files(idetag, cfg)
		
	end

	def environment_target_path
		if self.class.configure.deploy_to_bin
			self.out_path.glob("#{idetag}/*/*/bin/")
		else
			[self.out_path]
		end
	end

end
