
module Interface
	def self.included(other)
		super
		other.extend(ClassMethods)
	end
	module ClassMethods
		def echo(msg)
			puts msg
		end
	end
end

class Example
	include Interface
end

class Final < Example
end

p Example.ancestors
# => [Example, Object, Kernel, BasicObject]

Example.echo("Echo was called on Example")
Final.echo("Echo was called on Final")