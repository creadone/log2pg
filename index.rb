require 'json'
require 'json/repair'
require 'csv'
require 'set'
require 'tempfile'
require 'ruby-progressbar'

require './core_ext/hash'

require './flatter'
require './db'

file_name = ARGV[0].strip

unless File.exist?(file_name)
  raise Exception.new("Input file not exists") 
end

input_file_size = `cat #{file_name} | wc -l`.to_i
input_file_name = File.basename(file_name)
input_file_path = File.expand_path(input_file_name)

output_csv_name = File.basename(input_file_name, File.extname(input_file_name))
output_csv_path = File.join(File.dirname(input_file_path), "#{output_csv_name}.csv")
output_csv      = CSV.open(output_csv_path, 'w', force_quotes: true, col_sep: ',')

output_schema_name = File.basename(input_file_name, File.extname(input_file_name))
output_schema_path = File.join(File.dirname(input_file_path), "#{output_schema_name}.sql")
output_schema      = File.open(output_schema_path, 'w')

temp_data_store = Tempfile.new("temp_data_#{Time.now.to_i}")

headers = Set.new
common_progress = ProgressBar.create(:format => "%t | %a %b\u{15E7}%i %p%%", :title => "Собираем заголовки", :progress_mark  => ' ', :remainder_mark => "\u{FF65}", :starting_at => 0, :total => input_file_size * 2)

File.open(input_file_path, 'r').each_line.with_index do |line, idx|

  # Парсим первый уровень
  begin
    log = JSON.parse(line)
  rescue => e
    raise e
  end

  # Парсим второй уровень
  log.each do |k,v|    

    # Парсим JSON в строке
    if v.is_a?(String) && v.start_with?('{')
      begin
        log[k] = JSON.parse(v)
      rescue => e
        log[k] = JSON.parse(JSON.repair(v)) rescue v
      end
    end

    # Парсим XML
    if v.is_a?(String) && v.start_with?('<')
      log[k] = Hash.from_xml(v)
    end

  end
  
  # Конвертируем ключи из символов в строки и схлопываем
  log = log.deep_transform_keys(&:to_s)
  log_flatten = Flatter.flatten(log)

  # Копим уникальные заголовки для второго прохода
  log_flatten.keys.map{|h| headers << h }

  # Сохраняем плоскую структуру в промежуточный файл
  temp_data_store.puts log_flatten.to_json
  temp_data_store.flush if idx % 1000 == 0

  common_progress.increment
end

# Выравниваем и конвертируем данные
temp_data_store_path = temp_data_store.path
temp_data_store.close

common_progress.title = "Выравниваем данные"

File.open(temp_data_store_path, 'r').each_line.with_index do |line, idx|
  row = []
  hash = JSON.parse(line)
  headers.map do |key|
    row.push hash.dig(key)
  end

  if idx == 0
    output_csv << headers.to_a
    create_table_data = DB.create_table_sql(
      output_schema_name,
      headers.to_a,
      row
    )
    output_schema << create_table_data
    output_schema.close
  end

  output_csv << row
  common_progress.increment
end

output_csv.close
output_schema.close
File.unlink(temp_data_store_path)

puts "\nЛоги обработаны \\o/ /o\\ \\o/ \n\n"
puts "Схема таблицы: #{output_schema.path}"
puts "Файл с данными: #{output_csv.path}"
puts "\n"