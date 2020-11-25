require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  # returns this object's class
  def model_class
    self.class_name.constantize
  end

  # returns this objects table
  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options.has_key?(:foreign_key) ? options[:foreign_key] : "#{name}_id".to_sym
    @primary_key = options.has_key?(:primary_key) ? options[:primary_key] : :id
    @class_name = options.has_key?(:class_name) ? options[:class_name] : "#{name.to_s.capitalize}"
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options.has_key?(:foreign_key) ? options[:foreign_key] : "#{self_class_name.to_s.downcase}_id".to_sym
    @primary_key = options.has_key?(:primary_key) ? options[:primary_key] : :id
    @class_name = options.has_key?(:class_name) ? options[:class_name] : "#{name.to_s.singularize.capitalize}"
  end
end

module Associatable
  # Phase IIIb
  # this is the method I got stuck on:
  # I reviewed the solution code and didn't get it,
  # copied it over and made it work and still didn't get it,
  # came back to it later and still didn't give it
  # and I have decided that stopping here is better than crying indefinitely over code
  def belongs_to(name, options = {})
    # saves the association name and options in a BelongsToOptions obj
    options = BelongsToOptions.new(name, options)

    # create the actual association method
    # belongs_to :cat,
    #   primary_key: :id,
    #   foreign_key: :cat_id,
    #   class_name: "Cat"
    # primary_key -> the current object's id in its own table
    # foreign_key -> the cat's id in the current' object's table
    # class_name  -> the name of the other class in the association
    define_method(name) do
      # get the foreign_key value
      for_val = self.send(options.foreign_key)
      # get the class_name from options#model_class
      # call #where on that class, looking for a row where the primary key is the desired cat
      # get the first record: that's the cat we want
      # return it
      options
        .model_class
        .where(options.primary_key => for_val)
        .first
    end
  end

  def has_many(name, options = {})
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
