class PhoneNumber
  include ActiveDoc

  takes :contact_name, String, :desc => "Name of person"
  takes :number, /^\d+$/, :desc => "Phone number"
  takes :options, Hash do
    takes :category, String, :desc => "Category of this contact"
  end

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
  
  def add(contact_name, number, options = {})
    @numbers << PhoneNumber.new(contact_name, number, options)
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