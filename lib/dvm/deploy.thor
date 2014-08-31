class Deploy < BuildTarget
	def self.environment_to_bin?
		@environment_to_bin || false
	end
	
	def self.environment_to_bin=(bool)
		@environment_to_bin = bool
	end

	def self.deploy_imports_for(idetag)
		return []
	end

protected

	def do_make(idetag, cfg)
		say "make deploy"
		deploy_environment(idetag, cfg)
		deploy_imports(idetag, cfg)
		deploy_other_files(idetag, cfg)
	end

	def deploy_imports(idetag, cfg)
		imports_to_deploy = self.class.deploy_imports_for(idetag)

		say "deploying imports"
		self.out_path.glob("#{idetag}/*/*/bin/") do |path_target|
			imports_to_deploy.each do |import_to_deploy|
				catch_product(path_target + import_to_deploy) do |path_to_deploy|
					path_source = vendor_imports_path + path_target.relative_path_from(out_path) + import_to_deploy
					get(path_source.to_s, path_to_deploy, force: true) if path_source.exist?
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
		if self.class.environment_to_bin?
			self.out_path.glob("#{idetag}/*/*/bin/")
		else
			[self.out_path]
		end
	end

end
