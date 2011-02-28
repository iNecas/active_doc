class ActiveDoc
  module MethodsDoc
    class Validator
      def initialize(name, type)
        @name = name
        @type = type
      end
      
      def validate(receiver, method)
        described_argument_index = method.parameters.find_index { |(arg, name)| name == @name }
        if described_argument_index
          expected_type = @type
          receiver.class_eval do
            self.send(:define_method, "#{method.name}_with_validation") do |*args|
              raise ArgumentError.new unless args[described_argument_index].is_a?(expected_type)
              self.send("#{method}_without_validation", *args)
            end
            self.send(:alias_method, :"#{method.name}_without_validation", method.name)
            self.send(:alias_method, method.name, :"#{method.name}_with_validation")
          end
        end
      end
      
    end
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def describe_arg(name, type)
        @validators ||= []
        @validators << ActiveDoc::MethodsDoc::Validator.new(name, type)
      end
      
      def method_added(method_name)
        if @validators
          @validators.each { |validator| validator.validate(self, self.instance_method(method_name)) }
          @validators = nil
        end
      end
    end
    
  end
end