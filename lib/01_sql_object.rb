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
    @table_name ||= self.name.tableize
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT #{self.table_name}.*
      FROM #{self.table_name}
    SQL
    parse_all(rows)
  end

  def self.parse_all(results)
    results.map { |row| self.new(row) }
  end

  def self.find(id)
    # finds the row with the matching id
    row = DBConnection.execute(<<-SQL, id)
      SELECT #{self.table_name}.*
      FROM #{self.table_name}
      WHERE #{self.table_name}.id = ?
    SQL
    # if there is no row, the query will return an empty array
    # if array is empty, return nil
    # otherwise create a new object and return it
    row.empty? ? (return nil) : (return self.new(row.first))
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
    self.class.columns.map { |col| send(col) }
  end

  def insert
    # don't use id column
    columns = self.class.columns.drop(1)
    # convert to string: dbconnection.execute doesn't use symbols
    col_names = columns.map(&:to_s).join(",")
    question_marks = (["?"] * columns.length).join(",")
    
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO #{self.class.table_name} (#{col_names})
    VALUES (#{question_marks})
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end
  
  def update
    columns = self.class.columns
    set = columns.drop(1).map! { |col| "#{col} = ?"}.join(", ")
    values = *attribute_values

    DBConnection.execute(<<-SQL, values.drop(1), values.first)
      UPDATE #{self.class.table_name}
      SET #{set}
      WHERE #{self.class.table_name}.id = ?
    SQL
  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end
