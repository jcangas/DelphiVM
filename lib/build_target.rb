
class BuildTarget < DvmTask
	attr_accessor :idetag
	attr_accessor :config
	attr_accessor :configs
	attr_accessor :platforms
	 		
protected
	def self.depends(*task_names)
		@depends ||=[]
		@depends.push(*task_names)
		@depends
	end
	
	def clear_products
		@products = [] 
	end
		
	def catch_products
		@catch_products = true
		yield
	ensure
		@catch_products = false
	end

	def catching_products?
		@catch_products
	end

	def catch_product(*prods)
		@products.push(*prods)
		yield(*prods) unless catching_products?
	end
	
	def do_clean(idetag, cfg)
		catch_products do
			do_make(idetag, cfg)
		end
		@products.each do |p| 
			remove_file(p, verbose: false) 
		end
	end
	
	def do_make(idetag, cfg)
	end

	def do_build(idetag, cfg)
		say_status "[clean]", ""
		invoke :clean
		say_status "[make]", ""
		invoke :make
	end

	def _build_path
		Pathname('out') + self.idetag
	end
	
	def self.publish  
		super  
		[:clean, :make, :build].each do |mth|
			desc "#{mth}", "#{mth} #{self.namespace} products"
			method_option :ide, type: :array, default: [IDEServices.default_ide], desc: "IDE list or ALL. #{IDEServices.default_ide} by default"
			method_option :props, type: :hash, aliases: '-p', default: {}, desc: "MSBuild properties. See MSBuild help"
			define_method mth do
				msbuild_params = options[:props]
				ides_to_call = options[:ide].any?{ |s| s.casecmp('all')==0 } ? IDEServices.ides_in_prj : IDEServices.ides_filter(options[:ide], :prj)
				ides_to_call.each do |idetag|          
					self.idetag = idetag
					self.config = msbuild_params
					self.configs =  IDEServices.configs_in_prj(idetag)
    				self.platforms = IDEServices.platforms_in_prj(idetag)
					self.clear_products
					self.class.depends.each { |task| self.invoke "#{task}:#{mth}" }
					send("do_#{mth}", idetag, msbuild_params)
				end
			end
		end
	end

end
 