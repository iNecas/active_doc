require 'spec_helper'
class PhoneBook
  include ActiveDoc
  attr_accessor :owner

  def initialize(owner)
    @numbers = []
    PhoneBook.register(self)
  end

  takes :contact_name, String
  def add(contact_name, number)
    @numbers << [contact_name, number]
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

describe ActiveDoc::Descriptions::MethodArgumentDescription do
  describe "more described methods" do
    subject { PhoneBook.new("Peter Smith") }
    context "instance method" do
      context "with wrong type" do
        it "raises ArgumentError" do
          lambda { subject.add(:catty_smith, "123456") }.should raise_error ArgumentError
        end
      end

      context "with correct type" do
        it "does not raise ArgumentError" do
          subject.add("Catty Smith", "123456")
          lambda { subject.add("Catty Smith", "123456") }.should_not raise_error ArgumentError
          lambda { subject.add("Catty Smith", 123456) }.should_not raise_error ArgumentError
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

  context "for description of optional parameter" do
    subject do
      Class.new do
        include ActiveDoc
        takes :conjunction, String
        def join(conjunction = ","); end
      end.new
    end

    it "validates only when argument is given" do
      lambda{ subject.join }.should_not raise_error ArgumentError
      lambda{ subject.join(";") }.should_not raise_error ArgumentError
      lambda{ subject.join(2) }.should raise_error ArgumentError
    end
  end

  context "with nested description of hash" do
    let :subject_class do
      Class.new do
        include ActiveDoc
        takes :options, Hash do
          takes :conjunction, String
        end
        def join(options); end
      end
    end

    context "when described key is not specified" do
      subject { lambda { subject_class.new.join({})} }

      it { should_not raise_error ArgumentError }
    end

    context "when described key has wrong value" do
      subject { lambda { subject_class.new.join(:conjunction => 2)} }

      it { should raise_error ArgumentError }
    end

    context "when described key has valid value" do
      subject { lambda { subject_class.new.join(:conjunction => ",")} }

      it { should_not raise_error ArgumentError }
    end

    context "when undescribed key is given" do
      subject { lambda { subject_class.new.join(:last_conjunction => "and")} }

      it { should raise_error ArgumentError }
    end

    describe "Rdoc comment" do
      subject { ActiveDoc::RdocGenerator.for_method(subject_class, :join) }

      it { should == <<RDOC }
# ==== Attributes:
# * +options+ :: (Hash):
#   * +:conjunction+ :: (String)
RDOC
    end
  end

  describe "none expectation specified" do
    let :subject_class do
      Class.new do
        include ActiveDoc
        takes :conjunction, :desc => "String between items when joining"
        def join(conjunction); end
      end
    end

    describe "Validation" do
      subject { lambda { subject_class.new.join(";") } }

      it { should_not raise_error ArgumentError }
    end

    describe "Rdoc comment" do
      subject { ActiveDoc::RdocGenerator.for_method(subject_class, :join)}

      it { should == <<RDOC }
# ==== Attributes:
# * +conjunction+ :: String between items when joining
RDOC
    end
  end

  describe "type argument expectation" do
    let :subject_class do
      Class.new do
        include ActiveDoc
        takes :conjunction, String
        def join(conjunction); end
      end
    end

    describe "Validation" do
      context "for valid value" do
        subject { lambda { subject_class.new.join(";") } }

        it { should_not raise_error ArgumentError }
      end

      context "for invalid value" do
        subject { lambda { subject_class.new.join(1) } }

        it { should raise_error ArgumentError }
      end
    end

    describe "Rdoc comment" do
      subject { ActiveDoc::RdocGenerator.for_method(subject_class, :join)}

      it { should == <<RDOC }
# ==== Attributes:
# * +conjunction+ :: (String)
RDOC
    end
  end

  describe "regexp argument expectation" do
    let :subject_class do
      Class.new do
        include ActiveDoc
        takes :conjunction, /^(and|or)$/
        def join(conjunction) ; end
      end
    end

    describe "Validation" do
      context "for valid value" do
        subject { lambda { subject_class.new.join("and") } }

        it { should_not raise_error ArgumentError }
      end

      context "for invalid value" do
        subject { lambda { subject_class.new.join("xor") } }

        it { should raise_error ArgumentError }
      end
    end

    describe "Rdoc comment" do
      subject { ActiveDoc::RdocGenerator.for_method(subject_class, :join) }

      it { should == <<RDOC }
# ==== Attributes:
# * +conjunction+ :: (/^(and|or)$/)
RDOC
    end
  end

  describe "array argument expectation" do
    let :subject_class do
      Class.new do
        include ActiveDoc
        takes :conjunction, %w{and or}
        def join(conjunction); end
      end
    end

    describe "Validation" do
      context "for valid value" do
        subject { lambda { subject_class.new.join("and") } }

        it { should_not raise_error ArgumentError }
      end

      context "for invalid value" do
        subject { lambda { subject_class.new.join("xor") } }

        it { should raise_error ArgumentError }
      end
    end

    describe "Rdoc comment" do
      subject { ActiveDoc::RdocGenerator.for_method(subject_class, :join) }

      it { should == <<RDOC }
# ==== Attributes:
# * +conjunction+ :: (["and", "or"])
RDOC
    end
  end


  describe "complex condition argument expectation" do
    let :subject_class do
      Class.new do
        include ActiveDoc
        takes(:number){|args| args[:number] != 0 }
        def divide(number) ; end
      end
    end

    describe "Validation" do
      context "for valid value" do
        subject { lambda { subject_class.new.divide(1) } }

        it { should_not raise_error ArgumentError }
      end

      context "for invalid value" do
        subject { lambda { subject_class.new.divide(0) } }

        it { should raise_error ArgumentError }
      end
    end

    describe "Rdoc comment" do
      subject { ActiveDoc::RdocGenerator.for_method(subject_class, :divide) }

      it { should == <<RDOC }
# ==== Attributes:
# * +number+ :: (Complex Condition)
RDOC
    end
  end

  describe "duck typing argument expectation" do
    let :subject_class do
      Class.new do
        include ActiveDoc
        takes :collection, :duck => :each
        takes :count, :duck => [:succ, :pred]
        def sum(collection, count); end
      end
    end

    describe "Validation" do
      context "for valid value" do
        subject { lambda { subject_class.new.sum([1,2,3], 2) } }

        it { should_not raise_error ArgumentError }
      end

      context "for invalid value" do
        subject { lambda { subject_class.new.sum(:s1_2_3, 2) } }

        it { should raise_error ArgumentError }
      end
    end

    describe "Rdoc comment" do
      subject { ActiveDoc::RdocGenerator.for_method(subject_class, :sum) }

      it { should == <<RDOC }
# ==== Attributes:
# * +collection+ :: (respond to :each)
# * +count+ :: (respond to [:succ, :pred])
RDOC
    end
  end


end

