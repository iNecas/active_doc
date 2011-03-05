require 'active_doc/documented_method'
module ActiveDoc
  VERSION = "0.1.0.beta.3"
  def self.included(base)
    base.extend(ClassMethods)
    base.extend(Dsl)
    base.class_eval do
      class << self
        extend(Dsl)
      end
    end
  end

  class << self
    def register_validator(validator)
      @current_validators ||= []
      @current_validators << validator
    end
    
    def pop_current_validators
      current_validators = @current_validators
      @current_validators = nil
      return current_validators
    end
    
    def nested_validators
      before_nesting_validators = self.pop_current_validators
      yield
      after_nesting_validators = self.pop_current_validators
      @current_validators = before_nesting_validators
      return after_nesting_validators
    end

    def validate(base, method_name, origin)
      if method_validators = pop_current_validators
        @validators ||= {}
        @validators[[base, method_name]] = ActiveDoc::DocumentedMethod.new(base, method_name, method_validators, origin)
        before_method(base, method_name) do |method, args|
          args_with_vals = {}
          method.parameters.each_with_index { |(arg, name), i| args_with_vals[name] = {:val => args[i], :required => (arg != :opt), :defined => (i < args.size)}  }
          method_validators.each { |validator| validator.validate(args_with_vals) }
        end
      end
    end
    
    def documented_method(base, method_name)
      @validators && @validators[[base,method_name]]
    end
    
    def documented_methods
      @validators.values
    end

    def before_method(base, method_name)
      method = base.instance_method(method_name)
      base.class_eval do
        self.send(:define_method, "#{method_name}_with_validation") do |*args|
          yield method, args
          self.send("#{method_name}_without_validation", *args)
        end
        self.send(:alias_method, :"#{method_name}_without_validation", method_name)
        self.send(:alias_method, method_name, :"#{method_name}_with_validation")
      end
    end

  end

  module Dsl
  end
  
  module ClassMethods
    def method_added(method_name)
      ActiveDoc.validate(self, method_name, caller.first)
    end

    def singleton_method_added(method_name)
      ActiveDoc.validate(self.singleton_class, method_name, caller.first)
    end
  end
end
require 'active_doc/methods_doc'
require 'active_doc/rdoc_generator'

