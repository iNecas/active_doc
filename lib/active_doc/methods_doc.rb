require 'active_doc/methods_doc/argument_expectations'
module ActiveDoc
  module MethodsDoc
    class Validator
      attr_reader :origin_file, :origin_line, :argument_expectations
      attr_accessor :conjunction

      def initialize(name, argument_expectation, origin, options = {}, &block)
        @name = name
        @origin_file, @origin_line = origin.split(":")
        @origin_line           = @origin_line.to_i
        @description           = options[:desc]
        @argument_expectations = [ArgumentExpectation.find(argument_expectation)]
        if block
          @nested_validators = ActiveDoc.nested_validators do
            Class.new.extend(ActiveDoc::MethodsDoc::Dsl).class_exec(&block)
          end
        end
        @conjunction = :and
      end

      def validate(args_with_vals)
        argument_name = @name
        if arg_attributes = args_with_vals[@name]
          if arg_attributes[:required] || arg_attributes[:defined]
            current_value       = arg_attributes[:val]
            failed_expectations = @argument_expectations.find_all { |expectation| not expectation.fulfilled?(current_value) }
            if self.conjunction == :and && !failed_expectations.empty? || self.conjunction == :or && (failed_expectations == @argument_expectations)
              raise ArgumentError.new("Wrong value for argument '#{argument_name}'. Expected to #{failed_expectations.map { |expectation| expectation.expectation_to_s }.join(",")}; got #{current_value.class}")
            end
            if @nested_validators
              @nested_validators.each do |nested_validator|
                raise "Only hash is supported for nested argument documentation" unless current_value.is_a? Hash
                hash_args_with_vals = {}
                current_value.each {|key, value| hash_args_with_vals[key] = {:val => value, :defined => true}}
                nested_validator.validate(hash_args_with_vals)
              end
            end
          end
        else
          raise ArgumentError.new("Inconsistent method definition with active doc. Method was expected to have argument '#{argument_name}' to #{@argument_expectations.map { |expectation| expectation.expectation_to_s }.join(",")};")
        end
      end

      def to_rdoc
        "* +#{@name}+#{expectations_to_rdoc}#{desc_to_rdoc}"
      end

      private

      def expectations_to_rdoc
        " :: (#{@argument_expectations.map { |x| x.to_rdoc }.join(", ")})" unless @argument_expectations.empty?
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