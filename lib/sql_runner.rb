class SqlRunner
  include Singleton

  # Runs query and returns hash of results. Accepts the usual sanitize argument scheme.
  def run(*args)
    connection.execute(sanitize(*args)).tap do |res|
      res.type_map = type_map
    end
  end

  def sanitize(*args)
    ApplicationRecord.send(:sanitize_sql_array, args)
  end

  private

  def connection
    ApplicationRecord.connection
  end

  def type_map
    @type_map ||= PG::BasicTypeMapForResults.new(connection.raw_connection)
  end
end
