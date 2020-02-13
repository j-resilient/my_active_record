require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map { |k, v| "#{k.to_s} = ?"}.join(" AND ")

    results = DBConnection.execute(<<-SQL, params.values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{where_line}
    SQL

    results.map { |r| self.new(r) }
  end
end

class SQLObject
  extend Searchable
end
