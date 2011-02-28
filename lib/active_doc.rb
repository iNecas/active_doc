module ActiveDoc
  def self.included(base)
    base.extend(ClassMethods)
    base.extend(Dsl)
  end

  class << self
    def register_validator(validator)
      @current_validators ||= []
      @current_validators << validator
    end

    def validate(base, method_name)
      if @current_validators
        method_validators = @current_validators
        @current_validators     = nil
        @validators ||= {}
        @validators[[base, method_name]] = method_validators
        before_method(base, method_name, nil) do |method, args|
          method_validators.each { |validator| validator.validate(method, args) }
        end
      end
    end
    
    def validators_for_method(base, method_name)
      @validators && @validators[[base,method_name]]
    end

    def before_method(base, method_name, validator)
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
      ActiveDoc.validate(self, method_name)
    end
    
    def active_rdoc(method_name)
      ActiveDoc.validators_for_method(self, method_name).map{|validator| validator.to_rdoc}.join("\n")
    end
  end
end
require 'active_doc/methods_doc'
