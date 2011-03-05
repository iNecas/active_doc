module ActiveDoc
  module MethodsDoc
    class ArgumentExpectation
      def self.inherited(subclass)
        @argument_expectations ||= []
        @argument_expectations << subclass
      end
      
      def self.find(argument)
        @argument_expectations.each do |expectation|
          if suitable_expectation = expectation.from(argument)
            return  suitable_expectation
          end
        end
      end
    end
    
    class TypeArgumentExpectation < ArgumentExpectation
      def initialize(argument)
        @type = argument
      end
      
      def fulfilled?(value)
        value.is_a? @type
      end
      
      # Expected to...
      def expectation_to_s
        "be #{@type.name}"
      end
      
      def self.from(argument)
        if argument.is_a? Class
          self.new(argument)
        end
      end
    end

    class RegexpArgumentExpectation < ArgumentExpectation
      def initialize(argument)
        @regexp = argument
      end

      def fulfilled?(value)
        value =~ @regexp
      end

      # Expected to...
      def expectation_to_s
        "match #{@regexp}"
      end

      def self.from(argument)
        if argument.is_a? Regexp
          self.new(argument)
        end
      end
    end
    
    class Validator
      attr_reader :origin_file, :origin_line

      def initialize(name, argument_expectation, origin, options = {}, &block)
        @name = name
        @origin_file, @origin_line = origin.split(":")
        @origin_line = @origin_line.to_i
        @description = options[:desc]
        @argument_expectations = [ArgumentExpectation.find(argument_expectation)]
      end

      def validate(method, args)
        argument_name            = @name
        described_argument_index = method.parameters.find_index { |(arg, name)| name == argument_name }
        if described_argument_index
          optional_parameter = (method.parameters[described_argument_index].first == :opt && described_argument_index >= args.size)
          unless optional_parameter
            current_value = args[described_argument_index]
            failed_expectations = @argument_expectations.find_all{|expectation| not expectation.fulfilled?(current_value)}
            unless failed_expectations.empty?
              raise ArgumentError.new("Wrong value for argument '#{argument_name}'. Expected to #{failed_expectations.map{|expectation| expectation.expectation_to_s}.join(",")}; got #{current_value.class}")
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