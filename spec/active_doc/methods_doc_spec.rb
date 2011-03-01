require 'spec_helper'
require File.expand_path("../../support/documented_class", __FILE__)

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

