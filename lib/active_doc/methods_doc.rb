module ActiveDoc
  module MethodsDoc
    class Validator
      def initialize(name, type)
        @name = name
        @type = type
      end

      def validate(method, args)
        argument_name            = @name
        expected_type            = @type
        described_argument_index = method.parameters.find_index { |(arg, name)| name == argument_name }
        if described_argument_index
          current_value = args[described_argument_index]
          raise ArgumentError.new("Wrong type for argument '#{argument_name}'. Expected #{expected_type}, got #{current_value.class}") unless current_value.is_a?(expected_type)
        else
          raise ArgumentError.new("Inconsistent method definition with active doc. Method was expected to have argument '#{argument_name}' of type #{expected_type}")
        end
      end

      def to_rdoc
        "@#{@name} :: (#{@type})"
      end
    end

    module Dsl
      def takes(name, type)
        ActiveDoc.register_validator(ActiveDoc::MethodsDoc::Validator.new(name, type))
      end
    end

  end
end
ActiveDoc::Dsl.send(:include, ActiveDoc::MethodsDoc::Dsl)