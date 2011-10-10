module ActiveDoc
  class DescribedMethod
    attr_reader :method, :descriptions
    def initialize(method)
      @method = method
      @descriptions = []
    end

    def line
      method.source_location.last
    end

    def file
      method.source_location.first
    end
  end
end
