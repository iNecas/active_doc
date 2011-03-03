class ClassWithMethodValidation
  include ActiveDoc

  takes :first_name, String
  takes :last_name, String

  def say_hello_to(first_name, last_name)
    return "Hello #{first_name} #{last_name}"
  end

  takes :message, String

# @message :: (String) - old
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
