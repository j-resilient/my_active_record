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
    @class_name = options.has_key?(:class_name) ? options[:class_name] : "#{name.to_s.camelcase}"
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options.has_key?(:foreign_key) ? options[:foreign_key] : "#{self_class_name.to_s.downcase}_id".to_sym
    @primary_key = options.has_key?(:primary_key) ? options[:primary_key] : :id
    @class_name = options.has_key?(:class_name) ? options[:class_name] : "#{name.to_s.singularize.camelcase}"
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # saves the association name and options in a BelongsToOptions obj
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

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
    # has_many :toys,
    #   primary_key: :id,
    #   foreign_key: :cat_id,
    #   class_name: "Toy"
    # primary_key -> cat's id
    # foreign_key -> the cat's id, stored in the toys table
    # class_name  -> the name of the other table, 'Toy'

    options = HasManyOptions.new(name, self, options)

    # define the association method
    define_method(name) do
      # get the foreign key
      for_val = self.send(options.primary_key)
      options
        .model_class
        .where(options.foreign_key => for_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
