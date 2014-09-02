module PathMethods
	def self.extension(rootpath= '')
		mod = Module.new do
			def method_missing(name, *args, &block)
				(m = name.to_s.match(/(\w+)_path$/)) ? _to_path(m[1], *args) : super
			end
		private
			def _to_path(under_scored_name='', rel: false)
				paths = under_scored_name.to_s.stripdup('_').split('_')
				paths.unshift('root') unless (paths[0] == "root") || rel
				paths = paths.map{|p| respond_to?("_#{p}_path", true) ? send("_#{p}_path") : p}
				paths.unshift(Pathname('')).inject(:+)
			end
		end

		mod.class_eval do 
			define_method :_root_path do
				@get_root ||= rootpath.to_s
			end
		end
		mod
	end
end

class BuildTarget < Delphivm
	attr_accessor :idetag
	attr_accessor :config
	attr_accessor :configs
	attr_accessor :platforms
	 	
	include PathMethods.extension(ROOT)
  include Thor::Actions
	
	def self.inherited(klass)
		klass.source_root(ROOT)
		klass.publish
	end
	
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
			remove_file(p) 
		end
	end
	
	def do_make(idetag, cfg)
	end

	def do_build(idetag, cfg)
		invoke :clean
		invoke :make
	end

	def invocation
		_shared_configuration[:invocations][self.class].last
	end

	def self.publish    
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

	def _build_path
		Pathname('out') + self.idetag
	end
	
end
 