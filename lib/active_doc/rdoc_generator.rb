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

      def visit(object, *args)
        visitor = self.class.find_visitor(object)
        object.instance_exec(self, *args, &visitor)
      end

      register Descriptions::ArgumentDescription::TypeArgumentExpectation do |visitor|
        @type.name
      end

      register Descriptions::ArgumentDescription::RegexpArgumentExpectation do |visitor|
        @regexp.inspect.gsub('\\') { '\\\\' }
      end

      register Descriptions::ArgumentDescription::ArrayArgumentExpectation do |visitor|
        @array.inspect
      end

      register Descriptions::ArgumentDescription::ComplexConditionArgumentExpectation do |visitor|
        "Complex Condition"
      end

      register Descriptions::ArgumentDescription::OptionsHashArgumentExpectation do |visitor|
        "Hash"
      end

      register Descriptions::ArgumentDescription::DuckArgumentExpectation do |visitor|
        respond_to = @respond_to
        respond_to = respond_to.first if respond_to.size == 1
        "respond to #{respond_to.inspect}"
      end

      register Descriptions::ArgumentDescription do |visitor, hash|
        name = hash ? @name.inspect : @name
        ret = "* +#{name}+"
        ret << expectations_to_rdoc.to_s
        ret << desc_to_rdoc.to_s
        ret << expectations_to_additional_rdoc.to_s
        ret
      end
    end


    def self.for_method(base, method_name)
      if documented_method = ActiveDoc.documented_method(base, method_name)
        documented_method.to_rdoc
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
