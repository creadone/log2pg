module Flatter
  def self.flatten(hash, parent_key = '', result = {})
    hash.each do |key, value|
      new_key = parent_key.empty? ? key.to_s : "#{parent_key}.#{key}"
      case value
      when Hash
        flatten(value, new_key, result)
      when Array
        value.each_with_index do |item, index|
          if item.is_a?(Hash) || item.is_a?(Array)
            flatten({ index => item }, new_key, result)
          else
            result["#{new_key}_#{index}"] = item
          end
        end
      else
        result[new_key] = value
      end
    end
    result
  end
end