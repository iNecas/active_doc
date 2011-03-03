require 'active_doc/documented_method'
module ActiveDoc
  VERSION = "0.1.0.beta.2"
  def self.included(base)
    base.extend(ClassMethods)
    base.extend(Dsl)
  end

  class << self
    def register_validator(validator)
      @current_validators ||= []
      @current_validators << validator
    end

    def validate(base, method_name, origin)
      if @current_validators
        method_validators = @current_validators
        @current_validators     = nil
        @validators ||= {}
        @validators[[base, method_name]] = ActiveDoc::DocumentedMethod.new(base, method_name, method_validators, origin)
        before_method(base, method_name) do |method, args|
          method_validators.each { |validator| validator.validate(method, args) }
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

