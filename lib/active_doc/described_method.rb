module ActiveDoc
  class DescribedMethod
    attr_reader :origin_file, :origin_line, :descriptions
    def initialize(base, method_name, descriptions, origin)
      @base, @method_name, @descriptions = base, method_name, descriptions
      @origin_file, @origin_line = origin.split(":")
      @origin_line = @origin_line.to_i
    end
    
    def to_rdoc
      rdoc_lines = descriptions.map {|x| x.to_rdoc.lines.map{ |l| "# #{l.chomp}" }}.flatten
      rdoc_lines.unshift("# ==== Attributes:")
      return rdoc_lines.join("\n") << "\n"
    end
    
    def write_rdoc(offset)
      File.open(@origin_file, "r+") do |f|
        lines = f.readlines
        rdoc_lines = to_rdoc.lines.to_a
        rdoc_space_range = rdoc_space_range(offset)
        lines[rdoc_space_range] = rdoc_lines
        offset += rdoc_lines.size - rdoc_space_range.to_a.size
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
      (descriptions.last.last_line + offset)...(@origin_line + offset-1)
    end
    
  end
end