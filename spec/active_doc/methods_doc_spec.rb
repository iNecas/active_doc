require 'spec_helper'
class ClassWithMethodValidation
  include ActiveDoc

  takes :first_name, String
  takes :last_name, String

  def say_hello_to(first_name, last_name)
    return "Hello #{first_name} #{last_name}"
  end

  takes :message, String

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

describe ActiveDoc::MethodsDoc do
  describe "arguments validation" do
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
  end

end

