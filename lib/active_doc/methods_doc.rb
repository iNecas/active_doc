module ActiveDoc
  module MethodsDoc
    class Validator
      attr_reader :origin_file, :origin_line

      def initialize(name, type, origin, options = {}, &block)
        @name = name
        @type = type
        @origin_file, @origin_line = origin.split(":")
        @origin_line = @origin_line.to_i
        @description = options[:desc]
      end

      def validate(method, args)
        argument_name            = @name
        expected_type            = @type
        described_argument_index = method.parameters.find_index { |(arg, name)| name == argument_name }
        if described_argument_index
          current_value = args[described_argument_index]
          optional_parameter = (method.parameters[described_argument_index].first == :opt && described_argument_index >= args.size)
          unless current_value.is_a?(expected_type) || optional_parameter
            raise ArgumentError.new("Wrong type for argument '#{argument_name}'. Expected #{expected_type}, got #{current_value.class}")
          end
        else
          raise ArgumentError.new("Inconsistent method definition with active doc. Method was expected to have argument '#{argument_name}' of type #{expected_type}")
        end
      end

      def to_rdoc
        "* +#{@name}+#{type_to_rdoc}#{desc_to_rdoc}"
      end

      private

      def type_to_rdoc
        " :: (#{@type})" if @type
      end

      def desc_to_rdoc
        " :: #{@description}" if @description
      end
    end

    module Dsl
      def takes(name, type, options = {}, &block)
        ActiveDoc.register_validator(ActiveDoc::MethodsDoc::Validator.new(name, type, caller.first, options, &block))
      end
    end

  end
end
ActiveDoc::Dsl.send(:include, ActiveDoc::MethodsDoc::Dsl)