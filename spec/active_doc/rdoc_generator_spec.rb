require 'spec_helper'
require File.expand_path("../../support/documented_class", __FILE__)

describe ActiveDoc::MethodsDoc do
  subject { ClassWithMethodValidation.new }
  
  it "generates rdoc description for a single method" do
    ActiveDoc::RdocGenerator.for_method(ClassWithMethodValidation, :say_hello_to).should == <<EXPECTED_OUTPUT.chomp
@first_name :: (String)
@last_name :: (String)
EXPECTED_OUTPUT
  end
  
  it "writes generated rdoc to file" do
    
  end

end

