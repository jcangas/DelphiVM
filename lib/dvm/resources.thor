class Resources < BuildTarget
	namespace :res

	self.configure do |cfg|
		cfg.res_files_ext! "dfm,fmx,res,dcr"
	end

protected

	def do_make(idetag, cfg)
		res_ext = self.class.configuration.res_files_ext
		IDEServices.platforms_in_prj(idetag).each do |prj_plat|
			IDEServices.configs_in_prj(idetag).each do |prj_cfg|
				say "resources for #{prj_plat}/#{prj_cfg}"
				lib_path = ROOT + 'out' + idetag + prj_plat + prj_cfg + 'lib'
				(ROOT + 'src' + "**{.*,}/*.{#{res_ext}}").glob.each do |res_file|
					 catch_product(lib_path + res_file.basename) do |product|
						get(res_file.to_s, product, verbose: false, force: true)
					 end
				end
			end
		end
	end
end