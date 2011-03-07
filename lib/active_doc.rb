require 'active_doc/described_method'
module ActiveDoc
  VERSION = "0.1.0"
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
    def register_description(description)
      @current_descriptions ||= []
      @current_descriptions << description
    end
    
    def pop_current_descriptions
      current_descriptions = @current_descriptions
      @current_descriptions = nil
      return current_descriptions
    end
    
    def nested_descriptions
      before_nesting_descriptions = self.pop_current_descriptions
      yield
      after_nesting_descriptions = self.pop_current_descriptions
      @current_descriptions = before_nesting_descriptions
      return after_nesting_descriptions
    end

    def describe(base, method_name, origin)
      if current_descriptions = pop_current_descriptions
        @descriptions ||= {}
        @descriptions[[base, method_name]] = ActiveDoc::DescribedMethod.new(base, method_name, current_descriptions, origin)
        before_method(base, method_name) do |method, args|
          args_with_vals = {}
          method.parameters.each_with_index { |(arg, name), i| args_with_vals[name] = {:val => args[i], :required => (arg != :opt), :defined => (i < args.size)}  }
          current_descriptions.each { |description| description.validate(args_with_vals) }
        end
      end
    end
    
    def documented_method(base, method_name)
      @descriptions && @descriptions[[base,method_name]]
    end
    
    def documented_methods
      @descriptions.values
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
      ActiveDoc.describe(self, method_name, caller.first)
    end

    def singleton_method_added(method_name)
      ActiveDoc.describe(self.singleton_class, method_name, caller.first)
    end
  end
end
require 'active_doc/descriptions'
require 'active_doc/rdoc_generator'

