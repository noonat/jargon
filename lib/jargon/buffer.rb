class Jargon
	class Buffer
		attr_reader :name, :lines, :value
		
		def initialize(value, name)
			@name = name
			@value = value
			@lines = @value.split("\n")
		end
		
		def to_s
			@value
		end
	end
end
