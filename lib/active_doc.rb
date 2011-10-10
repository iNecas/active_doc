$: << File.expand_path("../vendor/decorate/lib", File.dirname(__FILE__))
require 'decorate'

module ActiveDoc
  VERSION = "0.1.0"
  def self.included(base)
    base.extend(Dsl)
    base.class_eval do
      class << self
        extend(Dsl)
        if ActiveDoc.preloading?
          def method_missing(method, *args)
            return if method == :takes && ActiveDoc.preloading?
            super
          end
        end
      end
    end
  end

  class << self

    def preload!
      @preloading = true
      yield
      @preloading = false
    end

    def preloading?
      @preloading
    end
  end

end

module ActiveDoc
  class << self

    def perform_validation?
      if @perform_validation == false
        return false
      else
        return true
      end
    end

    def perform_validation=(value)
      @perform_validation = value
    end

    def description_target
      Thread.current[:active_doc_description_target]
    end

    def description_target=(description_target)
      Thread.current[:active_doc_description_target] = description_target
    end

    def register_description(method, description)
      @descriptions ||= {}
      @descriptions[[method.owner, method.name]] ||= ActiveDoc::DescribedMethod.new(method)
      @descriptions[[method.owner, method.name]].descriptions.insert(0,description)
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

files_to_preload = %w[active_doc/described_method.rb
                      active_doc/descriptions.rb
                      active_doc/rdoc_generator.rb]

ActiveDoc.preload! do
  files_to_preload.each {|f| require f }
end

files_to_preload.each {|f| load f }
