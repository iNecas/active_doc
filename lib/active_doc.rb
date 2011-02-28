module ActiveDoc
  def self.included(base)
    base.extend(ClassMethods)
  end

  class << self
    def register_validator(validator)
      @validators ||= []
      @validators << validator
    end

    def validate(base, method_name)
      if @validators
        used_validators = @validators
        @validators     = nil
        before_method(base, method_name, nil) do
          used_validators.each { |validator| validator.validate(base, base.instance_method(method_name)) }
        end
      end
    end

    def before_method(base, method_name, validator)
      base.class_eval do
        self.send(:define_method, "#{method_name}_with_validation") do |*args|
          self.send("#{method_name}_without_validation", *args)
        end
        self.send(:alias_method, :"#{method_name}_without_validation", method_name)
        self.send(:alias_method, method_name, :"#{method_name}_with_validation")
      end
    end

  end

  module ClassMethods
    def method_added(method_name)
      ActiveDoc.validate(self, method_name)
    end
  end
end
require 'active_doc/methods_doc'
