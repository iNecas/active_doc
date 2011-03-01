module ActiveDoc
  class RdocGenerator
    def self.for_method(base, method_name)
      if documented_method = ActiveDoc.documented_method(base, method_name)
        documented_method.validators.map { |validator| validator.to_rdoc }.join("\n")
      end
    end
  end
end