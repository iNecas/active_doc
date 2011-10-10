module ActiveDoc
  module Descriptions
    class ArgumentDescription
      include ActiveDoc
      module Dsl
        include ActiveDoc

        class << self
          def method_missing(method, *args)
            return if method == :takes && ActiveDoc.preloading?
            super
          end
        end
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

        takes :name, Symbol, :desc => "Name of the described argument"
        def takes(name, *args, &block)
          ActiveDoc.description_target = nil

          Decorate.decorate do |klass, method_name|
            ActiveDoc.description_target ||= DescriptionTarget::Method.new(klass.instance_method(method_name))
            description = ArgumentDescription.build(ActiveDoc.description_target, name, *args, &block)
            ActiveDoc.register_description(ActiveDoc.description_target.method, description)

            decorator_name = :takes
            wrapped_method_name = Decorate.create_alias(klass, method_name, decorator_name)

            klass.send(:define_method, method_name) do |*call_args, &call_block|
              description.validate(*call_args) if ActiveDoc.perform_validation?
              call = Decorate::AroundCall.new(self, method_name.to_sym, wrapped_method_name.to_sym, call_args, call_block)
              call.yield
            end
          end
        end
      end

      module DescriptionTarget

        class Method
          include ActiveDoc

          attr_reader :method
          takes :method, UnboundMethod
          def initialize(method)
            @method = method
          end

          takes :column_name, Symbol
          def find_value(column_name, *args)
            arg_index = @method.parameters.find_index { |(_, name)| name == column_name }
            required = @method.parameters[arg_index].first != :opt
            {:val => args[arg_index], :required => required, :defined => (arg_index < args.size)}
          end

          def to_s
            "#{@method.owner} #{@method.source_location.first}"
          end
        end

        class Hash
          include ActiveDoc

          takes :name, Symbol
          takes :hash, ::Hash
          def find_value(name, hash)
            {:val => hash[name], :defined => hash.has_key?(name)}
          end

          def to_s
            "Hash"
          end
        end

      end

      class ArgumentExpectation
        include ActiveDoc

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

        def children
          []
        end

        def fulfilled?(value)
          if self.condition?(value)
            @failed_value = nil
            return true
          else
            @failed_value = value
            return false
          end
        end
      end

      class TypeArgumentExpectation < ArgumentExpectation

        takes :argument, [Class, Module]
        def initialize(argument)
          @type = argument
        end

        def condition?(value)
          value.is_a? @type
        end

        # Expected to...
        def expectation_fail_to_s
          "be #{@type.name}, got #{@failed_value.class.name}"
        end

        def self.from(argument, options, proc)
          if argument.is_a?(Class) && proc.nil?
            self.new(argument)
          end
        end
      end

      class RegexpArgumentExpectation < ArgumentExpectation

        takes :argument, :duck => :match
        def initialize(argument)
          @regexp = argument
        end

        takes :value, String
        def condition?(value)
          value =~ @regexp
        end

        # Expected to...
        # NOTE: Possible thread-safe problem
        def expectation_fail_to_s
          "match #{@regexp}, got '#{@failed_value.inspect}'"
        end

        def self.from(argument, options, proc)
          if argument.is_a? Regexp
            self.new(argument)
          end
        end
      end

      class ArrayArgumentExpectation < ArgumentExpectation

        takes :argument, Array
        def initialize(argument)
          @array = argument
        end

        def condition?(value)
          @array.find {|expected| expected === value }
        end

        # Expected to...
        # NOTE: Possible thread-safe problem
        def expectation_fail_to_s
          "be included in #{@array.inspect}, got #{@failed_value.inspect}"
        end

        def self.from(argument, options, proc)
          if argument.is_a? Array
            self.new(argument)
          end
        end
      end

      class ComplexConditionArgumentExpectation < ArgumentExpectation

        takes :argument, :duck => :call
        def initialize(argument)
          @proc = argument
        end

        def condition?(value)
          @proc.call(value)
        end

        # Expected to...
        def expectation_fail_to_s
          "satisfy given condition, got #{@failed_value.inspect}"
        end

        def self.from(argument, options, proc)
          if proc.is_a?(Proc) && proc.arity == 1
            self.new(proc)
          end
        end
      end

      class OptionsHashArgumentExpectation < ArgumentExpectation

        takes :argument, :duck => :to_proc
        def initialize(argument)
          @proc = argument
          @hash_descriptions = []

          self.instance_exec(&@proc)
        end

        def takes(name, *args, &block)
          description_target = DescriptionTarget::Hash.new
          @hash_descriptions << ArgumentDescription.build(description_target, name, *args, &block)
        end

        def condition?(value)
          if @hash_descriptions
            raise "Only hash is supported for nested argument documentation" unless value.is_a? Hash
            described_keys   = @hash_descriptions.map do |hash_description|
              hash_description.validate(value)
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

        def children
          @hash_descriptions
        end

        def last_line
          @hash_descriptions && @hash_descriptions.last && (@hash_descriptions.last.last_line + 1)
        end

        def self.from(argument, options, block)
          if block.is_a?(Proc) && block.arity == 0 && argument == Hash
            self.new(block)
          end
        end
      end

      class DuckArgumentExpectation < ArgumentExpectation

        takes(:argument) {|value| value.is_a?(Symbol) or (value.is_a?(Array) and (value.all? {|v| v.is_a? Symbol}))}
        def initialize(argument)
          @respond_to = argument
          @respond_to = [@respond_to] unless @respond_to.is_a? Array
        end

        def condition?(value)
          @failed_quacks = @respond_to.find_all {|quack| not value.respond_to? quack}
          @failed_quacks.empty?
        end

        # Expected to...
        # NOTE: Possible thread-safe problem
        def expectation_fail_to_s
          "be respond to #{@respond_to.inspect}, missing #{@failed_quacks.inspect}"
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

      def self.build(description_target, name, *args, &block)
        if args.size > 1 || !args.first.is_a?(Hash)
          argument_expectation = args.shift || nil
        else
          argument_expectation = nil
        end
        options = args.pop || {}

        if ref_string = options[:ref]
          ArgumentDescription::Reference.new(description_target, name, ref_string, caller.first, options, &block)
        else
          ArgumentDescription.new(description_target, name, argument_expectation, caller.first, options, &block)
        end
      end

      takes :description_target, [DescriptionTarget::Method, DescriptionTarget::Hash]
      takes :name, Symbol
      takes :options, Hash do
        takes :duck, :ref => "ActiveDoc::Descriptions::ArgumentDescription::DuckArgumentExpectation#initialize"
        takes :desc, String
      end
      def initialize(description_target, name, argument_expectation, origin, options = {}, &block)
        @name, @origin, @description = name, origin, options[:desc]
        @description_target = description_target
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

      def validate(*args)
        return if @already_validating
        begin
          @already_validating = true
          if argument = @description_target.find_value(@name, *args)
            if argument[:required] || argument[:defined]
              current_value       = argument[:val]
              failed_expectations = @argument_expectations.find_all { |expectation| not expectation.fulfilled?(current_value) }
              if !failed_expectations.empty?
                raise ArgumentError.new("#{@description_target}: Wrong value for argument '#{@name}'. Expected to #{failed_expectations.map { |expectation| expectation.expectation_fail_to_s }.join(",")}")
              end
            end
          else
            raise ArgumentError.new("Inconsistent method definition with active doc. Method was expected to have argument '#{@name}'")
          end
        ensure
          @already_validating = false
        end
        return @name
      end

      def last_line
        return @last_line || self.origin_line
      end

      private

      class Reference < ArgumentDescription
        include Traceable

        takes :ref_string, /^\S+#\S+$/
        takes :options, :ref => "ActiveDoc::Descriptions::ArgumentDescription#initialize"
        def initialize(description_target, name, ref_string, origin, options)
          @name = name
          @klass, @method = ref_string.split("#")
          names = @klass.split("::")
          @klass = names.inject(Object) {|k, name| k.const_get(name) }
          @method = @method.to_sym
          @origin = origin
        end

        def validate(*args)
          # we validate only in target method
          return @name
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
ActiveDoc::Dsl.send(:include, ActiveDoc::Descriptions::ArgumentDescription::Dsl)
