module ActiveDoc
  class DescribedMethod
    attr_reader :origin_file, :origin_line, :descriptions
    def initialize(base, method_name, origin)
      @base, @method_name, @descriptions = base, method_name, []
      @origin_file, @origin_line = origin.split(":")
      @origin_line = @origin_line.to_i
    end
  end
end
