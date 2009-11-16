class Jargon
	class Comment
		attr_reader :buffer, :node
		
		def initialize(comments, nodes, buffer)
			@buffer = buffer
			@comments = comments
			@node = nodes[0] rescue nil
		end
		
		def node?
			!@node.nil?
		end
		
		def to_s
			value
		end
		
		def value
			@value ||= @comments.map { |c| c.comment_value }.join "\n"
		end
	end
end
