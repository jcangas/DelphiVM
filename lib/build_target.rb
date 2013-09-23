﻿class BuildTarget < Thor
	attr_accessor :idetag
	attr_accessor :config
	 
	INCL_BUILD = /(_|\/|\A)build(_|\/|\Z)/ # REX for recognize a build subpath
	
	include Thor::Actions
	
	def self.inherited(klass)
		klass.source_root(ROOT)
		klass.publish
	end

	def method_missing(name, *args, &block)
		if name.to_s.match(/(\w+)_path$/)
			convert_to_path $1
		else
			super
		end
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

	def catch_product(*prods)
		@products.push(*prods)
		yield *prods unless @catch_products
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

	def self.publish    
		[:clean, :make, :build].each do |mth|
			desc "#{mth}", "#{mth} #{self.namespace} products"
			method_option :params,  type: :hash, aliases: '-p', default: {:Config => 'Debug'}, desc: "more MSBuild params. See MSBuild help"
			define_method mth do
				msbuild_params = options[:params]
				IDEServices.ideused.each do |idetag|          
					self.idetag = idetag
					self.config = msbuild_params
					self.clear_products
					self.class.depends.each { |task| self.invoke "#{task}:#{mth}" }
					send("do_#{mth}", idetag, msbuild_params)
				end
			end
		end
	end

	def convert_to_path(under_scored='')
		buildpath_as_str = (Pathname('out') + self.idetag + self.config[:Config]).to_s    
		ROOT + under_scored.to_s.split('_').join('/').gsub(INCL_BUILD, '\1' + buildpath_as_str + '\2')
	end
	
end