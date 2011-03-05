require 'spec_helper'
class PhoneBook
  include ActiveDoc
  attr_accessor :owner
  
  def initialize(owner)
    @numbers = []
    PhoneBook.register(self)
  end

  takes :contact_name, String
  takes :number, /[0-9]{6}/
  takes :options, Hash
  def add(contact_name, number, options = {})
    @numbers << [contact_name, number, options]
  end

  takes :owner, String
  def self.find_for_owner(owner)
    @phone_books && @phone_books[owner]
  end
  
  class << self
    takes :phone_book, PhoneBook
    def register(phone_book)
      @phone_books ||= {}
      @phone_books[phone_book.owner] = phone_book
    end
  end

  def self.phone_books
    return @phone_books.values
  end

  def size
    return @numbers.size
  end
end

describe ActiveDoc::MethodsDoc do
  describe "arguments validation" do
    subject { PhoneBook.new("Peter Smith") }
    context "instance method" do
      context "with wrong type" do
        it "raises ArgumentError" do
          lambda { subject.add("Catty Smith", 123456) }.should raise_error ArgumentError
          lambda { subject.add(:catty_smith, "123456") }.should raise_error ArgumentError
          lambda { subject.add("Catty Smith", "123456", "{:category => 'family'}") }.should raise_error ArgumentError
        end
      end

      context "with correct type" do
        it "does not raise ArgumentError" do
          subject.add("Catty Smith", "123456")
          lambda { subject.add("Catty Smith", "123456") }.should_not raise_error ArgumentError
          lambda { subject.add("Catty Smith", "123456", {:category => "family"}) }.should_not raise_error ArgumentError
        end
      end

      context "without argument validation" do
        it "does not raise ArgumentError" do
          lambda { subject.size }.should_not raise_error ArgumentError
        end
      end
    end

    context "class method" do
      context "with wrong type" do
        it "raises ArgumentError" do
          lambda { subject.class.find_for_owner(:peter_smith) }.should raise_error ArgumentError
        end
      end

      context "with correct type" do
        it "does not raise ArgumentError" do
          lambda { subject.class.find_for_owner("Peter Smith") }.should_not raise_error ArgumentError
        end
      end

      context "without argument validation" do
        it "does not raise ArgumentError" do
          lambda { subject.class.phone_books }.should_not raise_error ArgumentError
        end
      end
    end
  end

end

