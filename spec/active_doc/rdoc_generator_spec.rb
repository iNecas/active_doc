require 'spec_helper'

describe ActiveDoc::MethodsDoc do
  let(:documented_class_path) { File.expand_path("../../support/documented_class.rb", __FILE__) }
  before(:each) do
    @original_documented_class = File.read(documented_class_path)
    load documented_class_path
  end
  
  after(:each) do
    File.open(documented_class_path, "w") {|f| f << @original_documented_class}
  end
  
  it "generates rdoc description for a single method" do
    ActiveDoc::RdocGenerator.for_method(ClassWithMethodValidation, :say_hello_to).should == <<EXPECTED_OUTPUT
# ==== Attributes:
# * +first_name+ :: (String) :: First name of the person
# * +last_name+ :: (String) :: Last name of the person
EXPECTED_OUTPUT
  end

  it "writes generated rdoc to file" do
    ActiveDoc::RdocGenerator.write_rdoc
    documented_class = File.read(documented_class_path)
    documented_class.should == <<RUBY
class ClassWithMethodValidation
  include ActiveDoc

  takes :first_name, String, :desc => "First name of the person"
  takes :last_name, String, :desc => "Last name of the person"
# ==== Attributes:
# * +first_name+ :: (String) :: First name of the person
# * +last_name+ :: (String) :: Last name of the person
  def say_hello_to(first_name, last_name)
    return "Hello \#{first_name} \#{last_name}"
  end

  takes :message, String
# ==== Attributes:
# * +message+ :: (String)
  def self.announce(message)
    return "People of the Earth, hear the message: '\#{message}'"
  end

  def self.announce_anything(sound)
    return "People of the Earth, hear the sound: '\#{sound}'"
  end

  def say_hello_to_any_name(name)
    return "Hello \#{name}"
  end
end
RUBY
  end

end

