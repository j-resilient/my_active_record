require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # execute2 returns a list of column names as its first element
    # otherwise we'd just use execute
    # and neither execute nor execute2 let you interpolate the from statement with '?'
    # instead we have to use string interpolation #{}
    return @columns unless @columns.nil?
    columns = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{self.table_name}
      LIMIT 0
    SQL
    @columns = columns.flatten.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) { self.attributes[col] }
      define_method("#{col}=") { |val| self.attributes[col] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.tableize
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
    SQL
    parse_all(rows)
  end

  def self.parse_all(results)
    results.map { |row| self.new(row) }
  end

  def self.find(id)
    # ...
  end

  def initialize(params = {})
    params.each do |col, val|
      # turn the column name into a symbol
      col = col.to_sym
      # raise an error if column doesn't exist
      # self.class gets the name of the current class
      raise "unknown attribute '#{col}'" unless self.class.columns.include?(col)

      # call the setter for the current column 
      self.send("#{col}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # ...
  end

  def insert
    # ...
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
