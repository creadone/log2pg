module DB

  MAPPING = {
    "Integer"    => "BIGINT",
    "String"     => "TEXT",
    "TrueClass"  => "BOOLEAN",
    "FalseClass" => "BOOLEAN",
    "Float"      => "NUMERIC",
    "NilClass"   => "TEXT"
  }

  def self.resolve_types(anything)
    if anything.is_a?(Hash)
      anything = anything.values
    end
    anything.map(&:class).map do |type|
      MAPPING[type.to_s]
    end
  end

  def self.create_table_sql(name, keys, values)
    table_types = resolve_types(values)
    types = keys.zip(table_types).map do |key, type|
      "\t\"#{key}\" #{type}"
    end.join(", \n")
    str = ''
    str << "CREATE TABLE #{name} (\n#{types}\n);"
  end
end