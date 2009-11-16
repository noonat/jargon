class Jargon
	class Visitor
		include Java::OrgMozillaJavascriptAst::NodeVisitor
		
		def initialize(block)
			@block = block
		end
		
		def visit(node)
			@block.call(node)
			true
		end
	end
end
