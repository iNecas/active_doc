class ActiveDoc
  module MethodsDoc
    class Validator
      def initialize(name, type)
        @name = name
        @type = type
      end
      
      def validate(method)
        described_argument = method.parameters.find_index {|(arg, name)| name == @name}
        described_argument
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
        @validators.each {|validator| validator.validate(self.instance_method(method_name))}
      end
    end
    
  end
end