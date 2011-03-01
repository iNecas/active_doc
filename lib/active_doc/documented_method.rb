module ActiveDoc
  class DocumentedMethod
    attr_reader :validators
    def initialize(base, method_name, validators, origin)
      @base, @method_name, @validators, @origin = base, method_name, validators, origin
    end
  end
end