require 'spec_helper'

describe ActiveDoc::MethodsDoc do
  let(:documented_class_path) { File.expand_path("../../support/documented_class.rb", __FILE__) }
  before(:each) do
    @original_documented_class = File.read(documented_class_path)
    load documented_class_path
  end

  after(:each) do
    File.open(documented_class_path, "w") { |f| f << @original_documented_class }
  end

  it "generates rdoc description for a single method" do
    ActiveDoc::RdocGenerator.for_method(PhoneBook, :add).should == <<EXPECTED_OUTPUT
# ==== Attributes:
# * +contact_name+ :: (String) :: Name of person
# * +number+ :: (/^[0-9]+$/) :: Phone number
# * +options+ :: (Hash)
EXPECTED_OUTPUT
  end

  it "writes generated rdoc to file" do
    ActiveDoc::RdocGenerator.write_rdoc
    documented_class = File.read(documented_class_path)
    documented_class.should == <<RUBY.chomp
class PhoneBook
  include ActiveDoc
  attr_accessor :owner
  
  def initialize(owner)
    @numbers = []
    PhoneBook.register(self)
  end

  takes :contact_name, String, :desc => "Name of person"
  takes :number, /^[0-9]+$/, :desc => "Phone number"
  takes :options, Hash
# ==== Attributes:
# * +contact_name+ :: (String) :: Name of person
# * +number+ :: (/^[0-9]+$/) :: Phone number
# * +options+ :: (Hash)
  def add(contact_name, number, options = {})
    @numbers << [contact_name, number, options]
  end

  takes :owner, String
# ==== Attributes:
# * +owner+ :: (String)
  def self.find_for_owner(owner)
    @phone_books && @phone_books[owner]
  end
  
  class << self
    takes :phone_book, PhoneBook
# ==== Attributes:
# * +phone_book+ :: (PhoneBook)
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
RUBY
  end

end

