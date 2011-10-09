require 'spec_helper'

describe ActiveDoc::RdocGenerator do

  describe "rdoc output for descriptions" do
    subject { ActiveDoc::RdocGenerator.for_method(subject_class, :described_method) }

    describe "nested arguments" do
      let :subject_class do
        class_with_active_doc do
          takes :options, Hash do
            takes :conjunction, String
          end
          def described_method(options); end
        end
      end

      it { should == <<-RDOC }
# ==== Attributes:
# * +options+ :: (Hash):
#   * +:conjunction+ :: (String)
      RDOC
    end

    describe "description" do
      let :subject_class do
        Class.new do
          include ActiveDoc
          takes :conjunction, :desc => "String between items when joining"
          def described_method(conjunction); end
        end
      end

      it { should == <<-RDOC }
# ==== Attributes:
# * +conjunction+ :: String between items when joining
      RDOC
    end

    describe "type argument expectation" do
      let :subject_class do
        class_with_active_doc do
          takes :conjunction, String
          def described_method(conjunction); end
        end
      end

      it { should == <<-RDOC }
# ==== Attributes:
# * +conjunction+ :: (String)
      RDOC
    end

    describe "regexp argument expectation" do
      let :subject_class do
        class_with_active_doc do
          takes :conjunction, /^(and|or)$/
          def described_method(conjunction) ; end
        end
      end

      it { should == <<-RDOC }
# ==== Attributes:
# * +conjunction+ :: (/^(and|or)$/)
      RDOC
    end

    describe "array argument expectation" do
      let :subject_class do
        class_with_active_doc do
          takes :conjunction, %w{and or}
          def described_method(conjunction); end
        end
      end

      it { should == <<-RDOC }
# ==== Attributes:
# * +conjunction+ :: (["and", "or"])
      RDOC
    end

    describe "complex argument expectation" do
      let :subject_class do
        class_with_active_doc do
          takes(:number){|value| value != 0 }
          def described_method(number) ; end
        end
      end

      it { should == <<-RDOC }
# ==== Attributes:
# * +number+ :: (Complex Condition)
      RDOC
    end

    describe "duck argument expectation" do
      let :subject_class do
        class_with_active_doc do
          takes :collection, :duck => :each
          takes :count, :duck => [:succ, :pred]
          def described_method(collection, count); end
        end
      end

      it { should == <<-RDOC }
# ==== Attributes:
# * +collection+ :: (respond to :each)
# * +count+ :: (respond to [:succ, :pred])
      RDOC
    end
  end

  describe "saving the whole documentation" do
    let(:documented_class_path) { File.expand_path("../../support/documented_class.rb", __FILE__) }
    before(:each) do
      @original_documented_class = File.read(documented_class_path)
      load documented_class_path
    end

    after(:each) do
      File.open(documented_class_path, "w") { |f| f << @original_documented_class }
    end

    it "writes generated rdoc to temporary file" do
      pending "need to be rewritten - current state, when it affects the current file is not good"
      ActiveDoc::RdocGenerator.write_rdoc(documented_class_path)
      documented_class = File.read(documented_class_path)
      documented_class.chomp.should == <<-RUBY.chomp
class PhoneNumber
  include ActiveDoc

  takes :contact_name, String, :desc => "Name of person"
  takes :number, /^\\d+$/, :desc => "Phone number"
  takes :options, Hash do
    takes :category, String, :desc => "Category of this contact"
  end
# ==== Attributes:
# * +contact_name+ :: (String) :: Name of person
# * +number+ :: (/^\\\\d+$/) :: Phone number
# * +options+ :: (Hash):
#   * +:category+ :: (String) :: Category of this contact
  def initialize(contact_name, number, options = {})

  end
end
class PhoneBook
  include ActiveDoc
  attr_accessor :owner

  def initialize(owner)
    @numbers = []
    PhoneBook.register(self)
  end

  takes :contact_name, :ref => "PhoneNumber#initialize"
  takes :number, :ref => "PhoneNumber#initialize"
  takes :options, :ref => "PhoneNumber#initialize"
# ==== Attributes:
# * +contact_name+ :: (String) :: Name of person
# * +number+ :: (/^\\\\d+$/) :: Phone number
# * +options+ :: (Hash):
#   * +:category+ :: (String) :: Category of this contact
  def add(contact_name, number, options = {})
    @numbers << PhoneNumber.new(contact_name, number, options)
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

end

