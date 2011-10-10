class DocumentedPhoneNumber
  include ActiveDoc

  takes :contact_name, String, :desc => "Name of person"
  takes :number, /^\d+$/, :desc => "Phone number"
  takes :options, Hash do
    takes :category, String, :desc => "Category of this contact"
  end

  def initialize(contact_name, number, options = {})

  end
end
class DocumentedPhoneBook
  include ActiveDoc
  attr_accessor :owner

  def initialize(owner)
    @numbers = []
    DocumentedPhoneBook.register(self)
  end

  takes :contact_name, :ref => "DocumentedPhoneNumber#initialize"
  takes :number, :ref => "DocumentedPhoneNumber#initialize"
  takes :options, :ref => "DocumentedPhoneNumber#initialize"

  def add(contact_name, number, options = {})
    @numbers << DocumentedPhoneNumber.new(contact_name, number, options)
  end

  takes :owner, String

  def self.find_for_owner(owner)
    @phone_books && @phone_books[owner]
  end

  class << self
    takes :phone_book, DocumentedPhoneBook

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
