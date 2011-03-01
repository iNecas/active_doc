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

      describe_arg :message, String

      def self.announce(message)
        return "People of the Earth, hear the message: '#{message}'"
      end

      def self.announce_anything(sound)
        return "People of the Earth, hear the sound: '#{sound}'"
      end

      def say_hello_to_any_name(name)
        return "Hello #{name}"
      end
    end
    subject { ClassWithMethodValidation.new }
    context "instance method" do
      context "with wrong type" do
        it "raises ArgumentError" do
          lambda { subject.say_hello_to(0, "Necas") }.should raise_error ArgumentError
        end
      end

      context "with correct type" do
        it "does not raise ArgumentError" do
          lambda { subject.say_hello_to("Ivan", "Necas") }.should_not raise_error ArgumentError
        end
      end

      context "without argument validation" do
        it "does not raise ArgumentError" do
          lambda { subject.say_hello_to_any_name(0) }.should_not raise_error ArgumentError
        end
      end
    end

    context "class method" do
      context "with wrong type" do
        it "raises ArgumentError" do
          lambda { subject.class.announce(:be_arrogant) }.should raise_error ArgumentError
        end
      end

      context "with correct type" do
        it "does not raise ArgumentError" do
          lambda { subject.class.announce("be nice to each other") }.should_not raise_error ArgumentError
        end
      end

      context "without argument validation" do
        it "does not raise ArgumentError" do
          lambda { subject.class.announce_anything(0x4020D) }.should_not raise_error ArgumentError
        end
      end
    end

    it "generates rdoc description" do
      ClassWithMethodValidation.active_rdoc(:say_hello_to).should == <<EXPECTED_OUTPUT.chomp
@first_name :: (String)
@last_name :: (String)
EXPECTED_OUTPUT
    end
  end

end

