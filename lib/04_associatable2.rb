require_relative '03_associatable'
require_relative 'db_connection'

# Phase IV
module Associatable

  def has_one_through(name, through_name, source_name)
    
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      source_table = source_options.table_name
      through_table = through_options.table_name
      foreign_key_name = source_options.class_name.downcase + "_id"

      id = self.send(through_options.foreign_key)

      result = DBConnection.execute(<<-SQL, id)
        SELECT #{source_table}.*
        FROM #{through_table}
        JOIN #{source_table} ON #{through_table}.#{foreign_key_name} = #{source_table}.id
        WHERE #{through_table}.id = ?
        LIMIT 1
      SQL

      source_options.model_class.parse_all(result).first
    end
  end
end
