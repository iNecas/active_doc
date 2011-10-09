module ActiveDoc
  class RdocGenerator

    class Visitor

      class << self
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

      register Descriptions::ArgumentDescription::TypeArgumentExpectation do |visitor|
        visitor.append "(#{@type.name})"
      end

      register Descriptions::ArgumentDescription::RegexpArgumentExpectation do |visitor|
        regexp_str = @regexp.inspect.gsub('\\') { '\\\\' }
        visitor.append "(#{regexp_str})"
      end

      register Descriptions::ArgumentDescription::ArrayArgumentExpectation do |visitor|
        visitor.append "(#{@array.inspect})"
      end

      register Descriptions::ArgumentDescription::ComplexConditionArgumentExpectation do |visitor|
        visitor.append "(#{"Complex Condition"})"
      end

      register Descriptions::ArgumentDescription::OptionsHashArgumentExpectation do |visitor|
        visitor.append "(#{"Hash"})"
      end

      register Descriptions::ArgumentDescription::DuckArgumentExpectation do |visitor|
        respond_to = @respond_to
        respond_to = respond_to.first if respond_to.size == 1
        visitor.append "(respond to #{respond_to.inspect})"
      end

      register Descriptions::ArgumentDescription do |visitor|
        if @description_target.is_a? Descriptions::ArgumentDescription::DescriptionTarget::Hash
          visitor.new_line "* +:#{name}+"
        else
          visitor.new_line "* +#{name}+"
        end
        visitor.separator= " :: "
        @argument_expectations.each { |x| visitor.visit(x); visitor.separator=", " }
        visitor.separator=" " unless visitor.separator == " :: "
        visitor.append "#{@description}" unless @description.to_s.empty?
        @argument_expectations.each do |arg_expectations|
          visitor.separator= ":"
          visitor.shift_right
          arg_expectations.children.each do |child|
            visitor.visit(child)
          end
          visitor.shift_left
        end
        visitor.separator= nil
      end

      register ActiveDoc::DescribedMethod  do |visitor|
        visitor.new_line "==== Attributes:"
        descriptions.each {|x| visitor.visit(x)}
        visitor.render
      end
    end


    def self.for_method(base, method_name)
      if documented_method = ActiveDoc.documented_method(base, method_name)
        visitor = ActiveDoc::RdocGenerator::Visitor.new
        visitor.visit(documented_method)
      end
    end

    def self.write_rdoc(source_file_path = nil)
      files_and_methods = ActiveDoc.documented_methods.sort_by { |x| x.origin_line }.group_by { |x| x.origin_file }
      files_and_methods.delete_if { |file| file != source_file_path } if source_file_path
      files_and_methods.each do |origin_file, documented_methods|
        offset = 0
        yield origin_file, documented_methods if block_given?
        documented_methods.each do |documented_method|
          offset = documented_method.write_rdoc(offset)
        end
      end
    end
  end
end
