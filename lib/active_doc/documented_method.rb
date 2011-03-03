module ActiveDoc
  class DocumentedMethod
    attr_reader :origin_file, :origin_line, :validators
    def initialize(base, method_name, validators, origin)
      @base, @method_name, @validators = base, method_name, validators
      @origin_file, @origin_line = origin.split(":")
      @origin_line = @origin_line.to_i
    end
    
    def to_rdoc
      ret = validators.map { |validator| validator.to_rdoc }.join("\n# ") << "\n"
      ret.insert(0,"# ")
    end
    
    def write_rdoc(offset)
      File.open(@origin_file, "r+") do |f|
        lines = f.readlines
        rdoc_lines = to_rdoc.lines.to_a
        rdoc_space_range = rdoc_space_range(offset)
        lines[rdoc_space_range] = rdoc_lines
        offset += rdoc_space_range.to_a.size - rdoc_lines.size + 2
        f.pos = 0
        lines.each do |line|
          f.print line
        end
        f.truncate(f.pos)
      end
      return offset
    end
    
    protected
    def rdoc_space_range(offset)
      (validators.last.origin_line + offset)...(@origin_line + offset-1)
    end
    
  end
end