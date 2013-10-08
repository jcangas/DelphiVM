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

	def to_h
		result = {}
		each_pair do |k,v|
			result[k] = v.respond_to?(:to_h) ? v.to_h : v
		end
		result
	end		

	def load(io_or_filename)
		if io_or_filename.respond_to? :read
			io = io_or_filename
			owned_io = false
		else
			save(io_or_filename) unless File.exists?(io_or_filename.to_s)
			io = File.open(io_or_filename.to_s, 'r') 
			owned_io = true
		end
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

