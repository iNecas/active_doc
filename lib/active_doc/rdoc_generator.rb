module ActiveDoc
  class RdocGenerator

    class RdocVisitor

      class << self

        # registers a visitor procedure for the given class.
        # Procedure defined with the block will be evaluated in the context of
        # the visited object and takes one argument - the visitor object
        # itself - this allows cumulating the results in this visitor object.
        def register(klass, &block)
          @visitors ||= {}
          @visitors[klass] = block
        end

        def find_visitor(object)
          @visitors[object.class] or raise "Undefined visitor for klass #{object.class}"
        end
      end

      def initialize
        @lines, @indent_level, @shift_width = [], 0, 2
      end

      def shift_right
        @indent_level += 1
      end

      def shift_left
        @indent_level -= 1
      end

      def visit(object, *args)
        visitor = self.class.find_visitor(object)
        object.instance_exec(self, *args, &visitor)
      end

      def new_line(line)
        self.append("") unless @lines.empty? # to use the last separator
        @lines << (" "*@shift_width*@indent_level)
        self.append(line)
      end

      def append(string)
        @lines.last << @separator if @separator
        @separator = nil
        @lines.last << string
      end

      attr_accessor :separator

      def render
        out = @lines.map {|x| "# #{x}" }.join("\n")
        out << "\n"
        out
      end

      register Descriptions::ArgumentDescription::TypeArgumentExpectation do |rdoc|
        rdoc.append "(#{@type.name})"
      end

      register Descriptions::ArgumentDescription::RegexpArgumentExpectation do |rdoc|
        regexp_str = @regexp.inspect.gsub('\\') { '\\\\' }
        rdoc.append "(#{regexp_str})"
      end

      register Descriptions::ArgumentDescription::ArrayArgumentExpectation do |rdoc|
        rdoc.append "(#{@array.inspect})"
      end

      register Descriptions::ArgumentDescription::ComplexConditionArgumentExpectation do |rdoc|
        rdoc.append "(#{"Complex Condition"})"
      end

      register Descriptions::ArgumentDescription::OptionsHashArgumentExpectation do |rdoc|
        rdoc.append "(#{"Hash"})"
      end

      register Descriptions::ArgumentDescription::DuckArgumentExpectation do |rdoc|
        respond_to = @respond_to
        respond_to = respond_to.first if respond_to.size == 1
        rdoc.append "(respond to #{respond_to.inspect})"
      end

      register Descriptions::ArgumentDescription do |rdoc|
        if @description_target.is_a? Descriptions::ArgumentDescription::DescriptionTarget::Hash
          rdoc.new_line "* +:#{name}+"
        else
          rdoc.new_line "* +#{name}+"
        end
        rdoc.separator= " :: "

        @argument_expectations.each { |x| rdoc.visit(x); rdoc.separator=", " }

        rdoc.separator=" " unless rdoc.separator == " :: "
        rdoc.append "#{@description}" unless @description.to_s.empty?

        @argument_expectations.each do |arg_expectations|
          rdoc.separator= ":"
          rdoc.shift_right
          arg_expectations.children.each do |child|
            rdoc.visit(child)
          end
          rdoc.shift_left
        end

        rdoc.separator= nil
      end
      register Descriptions::ArgumentDescription::Reference do |rdoc|
        rdoc.visit(referenced_argument_description)
      end

      register ActiveDoc::DescribedMethod  do |rdoc|
        rdoc.new_line "==== Attributes:"
        descriptions.each {|x| rdoc.visit(x)}
      end
    end


    def self.for_method(documented_method)
      rdoc_visitor = ActiveDoc::RdocGenerator::RdocVisitor.new
      rdoc_visitor.visit(documented_method)
      rdoc_visitor.render
    end

    def self.write_rdoc(source_file_path, output_file_path)
      files_and_methods = ActiveDoc.documented_methods.sort_by { |x| x.line }.reverse.group_by(&:file)
      lines = File.read(source_file_path).lines.to_a
      files_and_methods[source_file_path].each do |documented_method|
        rdoc = RdocGenerator.for_method(documented_method)
        lines.insert(documented_method.line-1, *rdoc.lines.to_a)
      end
      File.open(output_file_path, "w") {|f| lines.each {|l| f << l} }
    end
  end
end
