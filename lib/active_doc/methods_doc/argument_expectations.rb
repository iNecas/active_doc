module ActiveDoc
  module MethodsDoc
    class ArgumentExpectation
      def self.inherited(subclass)
        @possible_argument_expectations ||= []
        @possible_argument_expectations << subclass
      end

      def self.find(argument)
        @possible_argument_expectations.each do |expectation|
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

      def to_rdoc
        @type.name
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

      def to_rdoc
        @regexp.inspect
      end

      def self.from(argument)
        if argument.is_a? Regexp
          self.new(argument)
        end
      end
    end

  end
end