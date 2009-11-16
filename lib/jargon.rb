require "js-1_7r3pre.jar"
require "jargon/ast.rb"
require "jargon/buffer.rb"
require "jargon/comment.rb"
require "jargon/visitor.rb"

class Jargon
	def initialize(pattern=nil)
		if pattern
			@pattern = if pattern.is_a? String
				Regexp.new "^#{Regexp.escape(pattern)}"
			elsif pattern.is_a? RegExp
				pattern
			else
				raise "pattern must be a Regexp or String"
			end
		end
		@observers = {}
		valid_types.each { |t| @observers[t] = [] }
	end
	
	def comments
		@comments ||= []
	end
	
	def on(type, opts={}, &block)
		raise_unless_valid_type type
		@observers[type] << block
		send(type).each { |n| block.call(n) }
	end
	
	def nodes
		@nodes ||= []
	end
	
	def read(glob, opts={})
		Dir.glob(glob).each do |filename|
			read_file(filename)
		end
	end
	
	def read_file(filename)
		read_string(open(filename).read(), filename)
	end
	
	def read_string(string, name='<string>')
		buffer = Buffer.new string, name
		parsed = parse(buffer)
		parsed[:merged_comments].each do |merged|
			nodes = parsed[:lines][merged.last.line + 1]
			self.comments << comment = Comment.new(merged, nodes, buffer)
			invoke_on(:comments, comment)
			if comment.node
				self.nodes << comment.node
				invoke_on(:nodes, comment.node)
			end
		end
	end
	
	private
	
	def invoke_on(type, node)
		raise_unless_valid_type type
		@observers[type].each do |block|
			block.call(node)
		end
	end
	
	def parse(buffer)
		comments, nodes, lines = [], [], {}
		visit(parser.parse(buffer.value, buffer.name, 1)) do |node|
			if node.comment?
				comments << node if @pattern.nil? or node.value =~ @pattern
			else
				nodes << node
				(lines[node.line] ||= []) << node
			end
		end
		merged, m = [], []
		comments.each do |c|
			unless m.empty? or c.merge?(m.last, lines)
				merged << m
				m = []
			end
			m << c
		end
		merged << m unless m.empty?
		{:comments=>comments, :merged_comments=>merged, :nodes=>nodes, :lines=>lines}
	end
	
	def parser
		context = Java::OrgMozillaJavascript::Context.enter()
		context.init_standard_objects()
		compiler_environs = Java::OrgMozillaJavascript::CompilerEnvirons.new
		compiler_environs.recording_comments = true
		compiler_environs.init_from_context(context)
		Java::OrgMozillaJavascript::Parser.new(compiler_environs, nil)
	end
	
	def raise_unless_valid_type type
		unless valid_types.include? type
			raise "invalid type, must be one of: " + valid_types.map {|t| ":#{t}" }.join(', ')
		end
	end
	
	def valid_types
		@valid_types ||= [:comments, :nodes]
	end
	
	def visit(ast, &block)
		visitor = Visitor.new block
		ast.visit_all(visitor)
	end	
end
