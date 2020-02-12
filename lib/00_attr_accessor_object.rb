class AttrAccessorObject
  def self.my_attr_accessor(*names)
    # creates a getter with name given name
    # define_method takes a symbol, but the instance_variable methods
    # can take a string or a symbol and need @ prepended in order
    # to find the instance variables
    names.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end

      # "=" has to be appended to the name to create the correct method
      define_method("#{name}=") do |val|
        instance_variable_set("@#{name}", val)
      end
    end
  end
end
