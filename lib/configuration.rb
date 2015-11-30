require 'json'
require 'ostruct'

module Configurable
	def self.included(other)
		class << other
			attr_accessor :configuration

			def configuration
				@configuration ||= Configuration.new
			end

			def configure(defaults=nil)
				self.configuration = Configuration.from_json(defaults.to_h.to_json) if defaults.respond_to?(:to_h)
				block_given? ? yield(self.configuration) : self.configuration
			end
		end
	end
end

class Configuration < OpenStruct
	class << self
		def from_json(source)
			 JSON.load(source, nil, {object_class: Configuration})
		end
	end

	def initialize(with_defaults=nil)
		super(with_defaults)
	end

	def each(*args, &block)
		 each_pair(*args, &block)
	end

	def deep_merge(other)
		dup.deep_merge!(other)
	end

	def deep_merge!(other)
		other.each_pair do |k,v|
			tv = self[k]
			self[k] = tv.is_a?(Configuration) && v.is_a?(Configuration) ? tv.deep_merge(v) : v
		end
		self
	end

	def method_missing(mid, *args, &block)
	 	mname = mid.id2name
	    len = args.length
	    if (mname.chomp!('=') || mname.chomp!('!')) && mid != :[]=
	    	raise ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1) if len != 1
	    elsif len == 0 && mid != :[]
				@table[mid] = Configuration.new if block
	    else
	      raise NoMethodError, "undefined method `#{mid}' for #{self}", caller(1)
	    end
	  	new_ostruct_member(mname)
      send(mid, *args, &block)
	end

	def new_ostruct_member(name)
	 	name = name.to_sym
	 	unless respond_to?(name)
			define_singleton_method(name) do |&block|
	    		value = @table[name]
	    		if value.is_a?(Configuration) && block
	    			block.call(value)
	    		else
	    			value
	    		end
	    	end
	    	define_singleton_method("#{name}=") { |x| modifiable[name] = x }
	    	define_singleton_method("#{name}!") { |x| modifiable[name] = x unless @table.has_key?(name)}
	  	end
	  name
	end

	def to_s
		to_h
	end

	def to_h
		result = {}
		each_pair do |k,v|
			result[k] = ((v.is_a?(Hash) || v.is_a?(Configuration)) ? v.to_h : v)
		end
		result
	end

	def load(io_or_filename, options={})
		if io_or_filename.respond_to? :read
			io = io_or_filename
			owned_io = false
		else
			io = File.open(io_or_filename.to_s, 'r')
			owned_io = true
		end
		save(io_or_filename) if !File.exist?(io_or_filename.to_s) && options[:create]
		r = io.read
		opts = Configuration.from_json(r)
		io.close if owned_io
		deep_merge!(opts) if opts
		self
	end

	def save(io_or_filename)
		if io_or_filename.respond_to? :write
			io = io_or_filename
			owned_io = false
		else
			io = File.open(io_or_filename.to_s, 'w')
			owned_io = true
		end
		io.write(JSON.pretty_generate(self.to_h))
		io.close if owned_io
		self
	end
end
