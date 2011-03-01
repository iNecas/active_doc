module ActiveDoc
  class RdocGenerator
    def self.for_method(base, method_name)
      ActiveDoc.validators_for_method(base, method_name).map{|validator| validator.to_rdoc}.join("\n")
    end
  end
end