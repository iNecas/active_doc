module ActiveDoc
  class RdocGenerator
    def self.for_method(base, method_name)
      if documented_method = ActiveDoc.documented_method(base, method_name)
        documented_method.to_rdoc
      end
    end

    def self.write_rdoc
      ActiveDoc.documented_methods.sort_by { |x| x.origin_line }.group_by { |x| x.origin_file }.each do |origin_file, documented_methods|
        offset = 0
        yield origin_file, documented_methods if block_given?
        documented_methods.each do |documented_method|
          offset += documented_method.write_rdoc(offset)
        end
      end
    end
  end
end