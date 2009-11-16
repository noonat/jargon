import Java::OrgMozillaJavascript::Token

unless nil.respond_to? :empty?
	class NilClass
		def empty?
			true
		end
	end
end

class Java::OrgMozillaJavascriptAst::AstNode
	def abs_identifier
		identifier rescue "<#{java_class}/#{type_name}>"
	end
	
	def comment?
		false
	end
	
	def line
		lineno
	end
	
	def type_name
		Token.type_to_name(type)
	end
	
	def to_s
		"#{line}#{'  ' * depth}#{type_name} ... #{java_class}"
	end
end

class Java::OrgMozillaJavascriptAst::Assignment
	def abs_identifier
		left.identifier
	end
end

class Java::OrgMozillaJavascriptAst::Comment
	def comment?
		true
	end
	
	def comment_value
		value = self.value
		case comment_type
		when Token::CommentType::LINE
			range, pattern = 0..-1, /^\/{2,}\s*|\s+$/
		when Token::CommentType::BLOCK
			range, pattern = 2..-3, /^\s*\/*\**\s*|\s+$/
		when Token::CommentType::JSDOC
			range, pattern = 3..-3, /^\s*\/*\**\s*|\s+$/
		when Token::CommentType::HTML
			range, pattern = 4..-4, /^\s+|\s+$/
		else
			raise "Unknown comment type \"#{comment_type}\""
		end
		value[range].split("\n").map { |line|
			line = line.gsub(pattern, '')
			if line.empty? then nil else line end
		}.compact.join("\n")
	end
	
	def merge?(other, lines=nil)
		return false if comment_type != other.comment_type
		return false if line - other.last_line > 1
		return false if lines and lines[line].empty?
		
	end
	
	def last_line
		line + value.count("\n")
	end
	
	def to_s
		"#{line}#{'  ' * depth}#{type_name}: #{to_source}"
	end
end

class Java::OrgMozillaJavascriptAst::ExpressionStatement
	def abs_identifier
		expression.abs_identifier
	end
end

class Java::OrgMozillaJavascriptAst::Name
	def abs_identifier
		pid = parent.abs_identifier
		id = identifier
		pid + '.' + id
	rescue
		identifier
	end
end

class Java::OrgMozillaJavascriptAst::FunctionCall
	def abs_identifier
		parent.abs_identifier rescue to_source
	end
end

class Java::OrgMozillaJavascriptAst::ObjectLiteral
	def abs_identifier
		parent.abs_identifier rescue to_source
	end
end

class Java::OrgMozillaJavascriptAst::ObjectProperty
	def abs_identifier
		(parent.abs_identifier + '.' rescue '') + left.identifier
	end
end

class Java::OrgMozillaJavascriptAst::PropertyGet
	def identifier
		to_source
	end
end
