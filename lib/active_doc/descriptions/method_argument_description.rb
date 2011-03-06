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
        # Describes method argument.
        #
        # ==== Attributes:
        # * +name+ :: name of method argument.
        # * +argument_expectation+ :: expected +Class+, +Regexp+ (or another values see +ArgumentExpectation+ subclasses
        #                             for more details).
        # * +options+:
        #   * +:ref+ :: (/^\\S+#\\S+$/) :: Reference to another method with description of this argument. Suitable when 
        #                                  passing argument to another method.
        #   * +:desc+ :: Textual additional description and explanation of argument 
        #
        # === Validation
        # 
        # When method is described, checking routines are attached to original method. When some argument
        # does not meet expectations, ArgumentError is raised.
        #
        # Argument description is not compulsory, e.g. when you not specify +takes+ for some argument, nothing
        # happens.
        # 
        # ==== Example:
        #
        #  takes :contact_name, String, :desc => "Last name of contact person"
        #  takes :number, /[0-9]{6}/
        #  def add(contact_name, number)
        #    ...
        #  end
        #
        # This adds to +add+ methods routines checking, that value of +contact_name+ ia_a? String and 
        # value of +add+ =~ /[0-9]{6}/.
        # 
        # === Nesting:
        # Takes can take a block, that allows additional description of argument using the same DSL.
        # Currently, it's used to describe Hash options.
        #
        # ==== Example:
        #
        #  takes :options do
        #    takes :category, String
        #  end
        #  def add(number, options)
        #    ...
        #  end
        #
        # ==== Hash validation:
        # In current implementation, when describing hash argument with nested description, every expected
        # key must be mentioned. Reason: preventing from mistakenly sending unexpected options.
        #
        # === RDoc generating
        # 
        # When generating +RDoc+ comments from +active_doc+, space between last +takes+ description an method definition
        # is used. *Bear in mind: Everything in this space will be replaced with generated comments*
        # ==== Example:
        #
        #  takes :contact_name, String, :desc => "Last name of contact person"
        #  takes :number, /[0-9]{6}/
        #  takes :options do
        #    takes :category, String
        #  end
        #  # this comment was there before
        #  def add(contact_name, number, options)
        #    ...
        #  end
        #
        # After running rake task for RDoc comments, it's changed to:
        #
        #  takes :contact_name, String, :desc => "Last name of contact person"
        #  takes :number, /[0-9]{6}/
        #  takes :options do
        #    takes :category, String
        #  end
        #  # ==== Arguments:
        #  # *+contact_name+ :: (String) :: Last name of contact person
        #  # *+number+ :: (/[0-9]{6}/) 
        #  # *+options+ :
        #  #   * +:category+ :: (String)
        #  def add(contact_name, number, options)
        #    ...
        #  end
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