module ActiveDoc
  module MethodsDoc
    class ArgumentAssertion
      def self.inherited(subclass)
        @argument_assertions ||= []
        @argument_assertions << subclass
      end
      
      def self.find(argument)
        @argument_assertions.each do |assertion|
          if matched_assertion = assertion.from(argument)
            return  matched_assertion
          end
        end
      end
    end
    
    class TypeArgumentAssertion < ArgumentAssertion
      def initialize(argument)
        @type = argument
      end
      
      def valid?(value)
        value.is_a? @type
      end
      
      # Expected to...
      def expectation_to_s
        "be #{@type.name}"
      end
      
      def self.from(argument)
        if argument.is_a? Class
          TypeArgumentAssertion.new(argument)
        end
      end
    end
    class Validator
      attr_reader :origin_file, :origin_line

      def initialize(name, argument_assertion, origin, options = {}, &block)
        @name = name
        @origin_file, @origin_line = origin.split(":")
        @origin_line = @origin_line.to_i
        @description = options[:desc]
        @argument_assertions = [ArgumentAssertion.find(argument_assertion)]
      end

      def validate(method, args)
        argument_name            = @name
        described_argument_index = method.parameters.find_index { |(arg, name)| name == argument_name }
        if described_argument_index
          optional_parameter = (method.parameters[described_argument_index].first == :opt && described_argument_index >= args.size)
          unless optional_parameter
            current_value = args[described_argument_index]
            invalid_assertions = @argument_assertions.find_all{|assertion| not assertion.valid?(current_value)}
            unless invalid_assertions.empty?
              raise ArgumentError.new("Wrong value for argument '#{argument_name}'. Expected to #{invalid_assertions.map{|assertion| assertion.expectation_to_s}.join(",")}; got #{current_value.class}")
            end
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