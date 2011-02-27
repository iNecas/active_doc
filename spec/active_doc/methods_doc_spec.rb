require 'spec_helper'

describe ActiveDoc::MethodsDoc do
  describe "arguments validation" do
    class ClassWithMethodValidation
      include ActiveDoc::MethodsDoc
      
      describe_arg :name, String
      def say_hello_to(name)
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
          lambda { subject.say_hello_to(0) }.should_not raise_error ArgumentError
        end
      end
    end
  end
  
end

