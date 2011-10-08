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

    def described_method
      Thread.current[:active_doc_method]
    end

    def described_method=(method)
      Thread.current[:active_doc_method] = method
    end

    def prepare_descriptions
      @descriptions ||= Hash.new {|h, (klass, method_name)| h[[klass, method_name]] = ActiveDoc::DescribedMethod.new(klass, method_name, caller[3]) }
    end

    def register_description(klass, method_name, description)
      prepare_descriptions
      @descriptions[[klass, method_name]].descriptions.insert(0,description)
    end

    def documented_method(base, method_name)
      @descriptions && @descriptions[[base,method_name]]
    end
    
    def documented_methods
      @descriptions.values
    end
  end

  module Dsl
  end
end
require 'active_doc/descriptions'
require 'active_doc/rdoc_generator'

