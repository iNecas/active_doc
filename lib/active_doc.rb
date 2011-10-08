$: << File.expand_path("../vendor/decorate/lib", File.dirname(__FILE__))
require 'decorate'
require 'active_doc/described_method'
module ActiveDoc
  VERSION = "0.1.0"
  def self.included(base)
    base.extend(Dsl)
    base.class_eval do
      class << self
        extend(Dsl)
      end
    end
  end

  class << self
    def prepare_descriptions
      @descriptions ||= Hash.new {|h, (klass, method_name)| h[[klass, method_name]] = ActiveDoc::DescribedMethod.new(klass, method_name, caller[3]) }
    end

    def described_method
      Thread.current[:active_doc_method]
    end

    def described_method=(method)
      Thread.current[:active_doc_method] = method
    end

    def register_description(klass, method_name, description)
      prepare_descriptions
      @descriptions[[klass, method_name]].descriptions.insert(0,description)
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
          current_descriptions.each { |description| description.validate(args_with_vals); }
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
end
require 'active_doc/descriptions'
require 'active_doc/rdoc_generator'

