module ActiveDoc
  module Descriptions
    class MethodArgumentDescription
      class ArgumentExpectation
        def self.inherited(subclass)
          @possible_argument_expectations ||= []
          @possible_argument_expectations << subclass
        end

        def self.find(argument)
          @possible_argument_expectations.each do |expectation|
            if suitable_expectation = expectation.from(argument)
              return  suitable_expectation
            end
          end
          return nil
        end
      end

      class TypeArgumentExpectation < ArgumentExpectation
        def initialize(argument)
          @type = argument
        end

        def fulfilled?(value)
          value.is_a? @type
        end

        # Expected to...
        def expectation_to_s
          "be #{@type.name}"
        end

        def to_rdoc
          @type.name
        end

        def self.from(argument)
          if argument.is_a? Class
            self.new(argument)
          end
        end
      end

      class RegexpArgumentExpectation < ArgumentExpectation
        def initialize(argument)
          @regexp = argument
        end

        def fulfilled?(value)
          value =~ @regexp
        end

        # Expected to...
        def expectation_to_s
          "match #{@regexp}"
        end

        def to_rdoc
          @regexp.inspect
        end

        def self.from(argument)
          if argument.is_a? Regexp
            self.new(argument)
          end
        end
      end
      attr_reader :name, :origin_file, :origin_line, :argument_expectations
      attr_accessor :conjunction

      def initialize(name, argument_expectation, origin, options = {}, &block)
        @name = name
        @origin_file, @origin_line = origin.split(":")
        @origin_line           = @origin_line.to_i
        @description           = options[:desc]
        @argument_expectations = []
        @argument_expectations << ArgumentExpectation.find(argument_expectation) if argument_expectation
        if block
          @nested_descriptions = ActiveDoc.nested_descriptions do
            Class.new.extend(Dsl).class_exec(&block)
          end
        end
        @conjunction = :and
      end

      def validate(args_with_vals)
        argument_name = @name
        if arg_attributes = args_with_vals[@name]
          if arg_attributes[:required] || arg_attributes[:defined]
            current_value       = arg_attributes[:val]
            failed_expectations = @argument_expectations.find_all { |expectation| not expectation.fulfilled?(current_value) }
            if self.conjunction == :and && !failed_expectations.empty? || self.conjunction == :or && (failed_expectations == @argument_expectations)
              raise ArgumentError.new("Wrong value for argument '#{argument_name}'. Expected to #{failed_expectations.map { |expectation| expectation.expectation_to_s }.join(",")}; got #{current_value.class}")
            end
            if @nested_descriptions
              raise "Only hash is supported for nested argument documentation" unless current_value.is_a? Hash
              hash_args_with_vals = {}
              current_value.each { |key, value| hash_args_with_vals[key] = {:val => value, :defined => true} }
              described_keys   = @nested_descriptions.map do |nested_description|
                nested_description.validate(hash_args_with_vals)
              end
              undescribed_keys = current_value.keys - described_keys
              unless undescribed_keys.empty?
                raise ArgumentError.new("Inconsistent options definition with active doc. Hash was not expected to have arguments '#{undescribed_keys.join(", ")}'")
              end
            end
          end
        else
          raise ArgumentError.new("Inconsistent method definition with active doc. Method was expected to have argument '#{argument_name}' to #{@argument_expectations.map { |expectation| expectation.expectation_to_s }.join(",")};")
        end
        return argument_name
      end

      def to_rdoc(hash = false)
        name = hash ? @name.inspect : @name
        "* +#{name}+#{expectations_to_rdoc}#{desc_to_rdoc}#{nested_to_rdoc}"
      end

      def last_line
        if @nested_descriptions
          @nested_descriptions.last.last_line + 1
        else
          self.origin_line
        end
      end

      private

      def expectations_to_rdoc
        " :: (#{@argument_expectations.map { |x| x.to_rdoc }.join(", ")})" unless @argument_expectations.empty?
      end

      def desc_to_rdoc
        " :: #{@description}" if @description
      end

      def nested_to_rdoc
        if @nested_descriptions
          ret = @nested_descriptions.map { |x| "  #{x.to_rdoc(true)}" }.join("\n")
          ret.insert(0, ":\n")
          ret
        end
      end
      
      class Reference < MethodArgumentDescription
        def initialize(name, target_description, origin, options)
          @name = name
          @klass, @method = target_description.split("#")
          @klass = Object.const_get(@klass)
          @method = @method.to_sym
          @origin_file, @origin_line = origin.split(":")
          @origin_line           = @origin_line.to_i
        end
        
        def validate(*args)
          # we validate only in target method
          return @name
        end
        
        def to_rdoc(*args)
            referenced_argument_description.to_rdoc
        end
        
        private
        
        def referenced_argument_description
          if referenced_described_method = ActiveDoc.documented_method(@klass, @method)
            if referenced_argument_description = referenced_described_method.descriptions.find { |description| description.name == @name }
              return referenced_argument_description
            end
          end
          raise "Missing referenced argument description '#{@klass.name}##{@method}'"
        end
      end

      module Dsl
        def takes(name, *args, &block)
          if args.size > 1 || !args.first.is_a?(Hash)
            argument_expectation = args.shift || nil
          else
            argument_expectation = nil
          end
          options = args.pop || {}
          if ref_string = options[:ref]
            ActiveDoc.register_description(ActiveDoc::Descriptions::MethodArgumentDescription::Reference.new(name, ref_string, caller.first, options, &block))
          else
            ActiveDoc.register_description(ActiveDoc::Descriptions::MethodArgumentDescription.new(name, argument_expectation, caller.first, options, &block))
          end
        end
      end

    end
  end
end
ActiveDoc::Dsl.send(:include, ActiveDoc::Descriptions::MethodArgumentDescription::Dsl)