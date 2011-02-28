require 'spec_helper'

describe ActiveDoc::MethodsDoc do
  describe "arguments validation" do
    class ClassWithMethodValidation
      include ActiveDoc
      
      describe_arg :first_name, String
      describe_arg :last_name, String
      def say_hello_to(first_name, last_name)
        return "Hello #{first_name} #{last_name}"
      end
      
      def say_hello_to_any_name(name)
        return "Hello #{name}"
      end
    end
    subject { ClassWithMethodValidation.new }
    context "on argument type" do
      context "with wrong type" do
        it "raises ArgumentError" do
          lambda { subject.say_hello_to(0) }.should raise_error ArgumentError
        end
      end
      
      context "with correct type" do
        it "does not raise ArgumentError" do
          lambda { subject.say_hello_to("Ivan") }.should_not raise_error ArgumentError
        end
      end
      
      context "without argument validation" do
        it "does not raise ArgumentError" do
          lambda { subject.say_hello_to_any_name(0) }.should_not raise_error ArgumentError
        end
      end
    end
  end
  
end

