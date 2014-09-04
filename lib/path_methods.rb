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
