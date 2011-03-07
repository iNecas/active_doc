module ActiveDoc
  module Descriptions
    class MethodArgumentDescription
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
        # When describing Hash, it can take a block, that allows additional description of argument 
        # using the same DSL.
        #
        # ==== Example:
        #
        #  takes :options, Hash do
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
        #  takes :options, Hash do
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
        #  takes :options, Hash do
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

      class ArgumentExpectation
        def self.inherited(subclass)
          @possible_argument_expectations ||= []
          @possible_argument_expectations << subclass
        end

        def self.find(argument, options, proc)
          @possible_argument_expectations.each do |expectation|
            if suitable_expectation = expectation.from(argument, options, proc)
              return  suitable_expectation
            end
          end
          return nil
        end


        def fulfilled?(value, args_with_vals)
          if self.condition?(value, args_with_vals)
            @failed_value = nil
            return true
          else
            @failed_value = value
            return false
          end
        end
        
        # to be inserted after argument description in rdoc
        def additional_rdoc
          return nil
        end
      end
      
      class TypeArgumentExpectation < ArgumentExpectation
        def initialize(argument)
          @type = argument
        end

        def condition?(value, args_with_vals)
          value.is_a? @type
        end

        # Expected to...
        def expectation_fail_to_s
          "be #{@type.name}, got #{@failed_value.class.name}"
        end

        def to_rdoc
          @type.name
        end

        def self.from(argument, options, proc)
          if argument.is_a?(Class) && proc.nil?
            self.new(argument)
          end
        end
      end

      class RegexpArgumentExpectation < ArgumentExpectation
        def initialize(argument)
          @regexp = argument
        end

        def condition?(value, args_with_vals)
          value =~ @regexp
        end

        # Expected to...
        # NOTE: Possible thread-safe problem
        def expectation_fail_to_s
          "match #{@regexp}, got '#{@failed_value.inspect}'"
        end

        def to_rdoc
          @regexp.inspect.gsub('\\') { '\\\\' }
        end

        def self.from(argument, options, proc)
          if argument.is_a? Regexp
            self.new(argument)
          end
        end
      end

      class ArrayArgumentExpectation < ArgumentExpectation
        def initialize(argument)
          @array = argument
        end

        def condition?(value, args_with_vals)
          @array.include?(value)
        end

        # Expected to...
        # NOTE: Possible thread-safe problem
        def expectation_fail_to_s
          "be included in #{@array.inspect}, got #{@failed_value.inspect}"
        end

        def to_rdoc
          @array.inspect
        end

        def self.from(argument, options, proc)
          if argument.is_a? Array
            self.new(argument)
          end
        end
      end
      
      class ComplexConditionArgumentExpectation < ArgumentExpectation
        def initialize(argument)
          @proc = argument
        end

        def condition?(value, args_with_vals)
          other_values = args_with_vals.inject({}) { |h, (k, v)| h[k] = v[:val];h }
          @proc.call(other_values)
        end

        # Expected to...
        def expectation_fail_to_s
          "satisfy given condition, got #{@failed_value.inspect}"
        end

        def to_rdoc
          "Complex Condition"
        end

        def self.from(argument, options, proc)
          if proc.is_a?(Proc) && proc.arity == 1
            self.new(proc)
          end
        end
      end
      
      class OptionsHashArgumentExpectation < ArgumentExpectation
        def initialize(argument)
          @proc = argument

          @hash_descriptions = ActiveDoc.nested_descriptions do
            Class.new.extend(Dsl).class_exec(&@proc)
          end
        end

        def condition?(value, args_with_vals)
          if @hash_descriptions
            raise "Only hash is supported for nested argument documentation" unless value.is_a? Hash
            hash_args_with_vals = value.inject(Hash.new{|h,k| h[k] = {:defined => false}}) do |hash, (key,val)|
              hash[key] = {:val => val, :defined => true}
              hash
            end
            described_keys   = @hash_descriptions.map do |hash_description|
              hash_description.validate(hash_args_with_vals)
            end
            undescribed_keys = value.keys - described_keys
            unless undescribed_keys.empty?
              raise ArgumentError.new("Inconsistent options definition with active doc. Hash was not expected to have arguments '#{undescribed_keys.join(", ")}'")
            end
          end
          return true
        end

        # Expected to...
        def expectation_fail_to_s
          "contain described keys, got #{@failed_value.inspect}"
        end

        def to_rdoc
          return "Hash"
        end

        def additional_rdoc
          if @hash_descriptions
            ret = @hash_descriptions.map { |x| "  #{x.to_rdoc(true)}" }.join("\n")
            ret.insert(0, ":\n")
            ret
          end
        end
        
        def last_line
          @hash_descriptions && @hash_descriptions.last && (@hash_descriptions.last.last_line + 1)
        end

        def self.from(argument, options, proc)
          if proc.is_a?(Proc) && proc.arity == 0 && argument == Hash
            self.new(proc)
          end
        end
      end

      class DuckArgumentExpectation < ArgumentExpectation
        def initialize(argument)
          @respond_to = argument
          @respond_to = [@respond_to] unless @respond_to.is_a? Array
        end

        def condition?(value, args_with_vals)
          @failed_quacks = @respond_to.find_all {|quack| not value.respond_to? quack}
          @failed_quacks.empty?
        end

        # Expected to...
        # NOTE: Possible thread-safe problem
        def expectation_fail_to_s
          "be respond to #{@respond_to.inspect}, missing #{@failed_quacks.inspect}"
        end

        def to_rdoc
          respond_to = @respond_to
          respond_to = respond_to.first if respond_to.size == 1
          "respond to #{respond_to.inspect}"
        end

        def self.from(argument, options, proc)
          if options[:duck]
            self.new(options[:duck])
          end
        end
      end


      module Traceable
        def origin_file
          @origin.split(":").first
        end
        
        def origin_line
          @origin.split(":")[1].to_i
        end
      end
      
      attr_reader :name, :origin_file
      attr_accessor :conjunction
      include Traceable

      def initialize(name, argument_expectation, origin, options = {}, &block)
        @name, @origin, @description = name, origin, options[:desc]
        @argument_expectations = []
        if found_expectation = ArgumentExpectation.find(argument_expectation, options, block)
          @argument_expectations << found_expectation
        elsif block
          raise "We haven't fount suitable argument expectations for given parameters"
        end
        
        if @argument_expectations.last.respond_to?(:last_line)
          @last_line = @argument_expectations.last.last_line
        end
      end

      def validate(args_with_vals)
        argument_name = @name
        if arg_attributes = args_with_vals[@name]
          if arg_attributes[:required] || arg_attributes[:defined]
            current_value       = arg_attributes[:val]
            failed_expectations = @argument_expectations.find_all { |expectation| not expectation.fulfilled?(current_value, args_with_vals) }
            if !failed_expectations.empty?
              raise ArgumentError.new("Wrong value for argument '#{argument_name}'. Expected to #{failed_expectations.map { |expectation| expectation.expectation_fail_to_s }.join(",")}")
            end
          end
        else
          raise ArgumentError.new("Inconsistent method definition with active doc. Method was expected to have argument '#{argument_name}'")
        end
        return argument_name
      end

      def to_rdoc(hash = false)
        name = hash ? @name.inspect : @name
        ret = "* +#{name}+"
        ret << expectations_to_rdoc.to_s
        ret << desc_to_rdoc.to_s
        ret << expectations_to_additional_rdoc.to_s
        return ret
      end

      def last_line
        return @last_line || self.origin_line
      end

      private

      def expectations_to_rdoc
        expectations_rdocs = @argument_expectations.map { |x| x.to_rdoc }.compact
        " :: (#{expectations_rdocs.join(", ")})" unless expectations_rdocs.empty?
      end
      
      def expectations_to_additional_rdoc
        @argument_expectations.map { |argument_expectation| argument_expectation.additional_rdoc }.compact.join
      end

      def desc_to_rdoc
        " :: #{@description}" if @description
      end

      class Reference < MethodArgumentDescription
        include Traceable
        def initialize(name, target_description, origin, options)
          @name = name
          @klass, @method = target_description.split("#")
          @klass = Object.const_get(@klass)
          @method = @method.to_sym
          @origin = origin
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


    end
  end
end
ActiveDoc::Dsl.send(:include, ActiveDoc::Descriptions::MethodArgumentDescription::Dsl)