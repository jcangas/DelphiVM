class Ship
	class FileSet
		attr :name
		attr :origin
		attr :filter
		def initialize(name, origin, filter= '**{.*,}/*.*', relative= true)
			super()
			@name = name
			@origin = Delphivm::ROOT + origin
			@filter = filter
			@relative = relative
		end

		def relative?
			@relative
		end
		
		def each(&block)
			list = origin.glob(filter)
			list = list.inject({}) do |hash, path| 
				key = (relative? ? path.relative_path_from(origin) : path.basename)
				hash[key] = path
				hash
			end
			list.each(&block)
		end
	end
end