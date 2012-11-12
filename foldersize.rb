#!/usr/bin/env ruby
$BYTES_IN_KiB = 2**10
$BYTES_IN_MiB = 2**20
$BYTES_IN_GiB = 2**30
def escape_double_quotes_in_string(string)
  pattern = /\"/
  string.gsub(pattern, "\\\"")
end

def get_size_string(size_in_bytes)
  if size_in_bytes > $BYTES_IN_GiB
    return "%f GiB" % (size_in_bytes.to_f / $BYTES_IN_GiB)
  elsif size_in_bytes > $BYTES_IN_MiB
    return "%f MiB" % (size_in_bytes.to_f / $BYTES_IN_MiB)
  elsif size_in_bytes > $BYTES_IN_KiB
    return "%f KiB" % (size_in_bytes.to_f / $BYTES_IN_KiB)
  else
    return "#{size_in_bytes} B"
  end
end

class FileDefinition
  attr_accessor :size_in_bytes,:path
  def initialize(path, size_in_bytes = nil)
    @path = path
    if size_in_bytes.nil?
      
      @size_in_bytes = 0
      begin
        @size_in_bytes = File.size(path)
      rescue Exception => e
        puts("exception getting size for file: #{path}")
      end
    else
      @size_in_bytes = size_in_bytes
    end
  end
    
  def to_json()
    p = escape_double_quotes_in_string(@path)
    return "\{ \"type\" : \"file\", \"path\" : \"#{p}\", \"size_in_bytes\": \"#{@size_in_bytes}\" \}"
  end
end

class DirectoryDefinition
  attr_accessor :path,:size_in_bytes,:file_list
  def initialize(path, size, file_list)
    @path, @size_in_bytes, @file_list = path, size, file_list
  end
  
  def to_json()
    files = "["
    @file_list.each {|f|
      unless files.empty?
        files += ", "
      end
      files = files + f.to_json()
    }
    files += "]"
    p = escape_double_quotes_in_string(@path)
    return "\{ \"type\" : \"directory\", \"path\" : \"#{p}\", \"size_in_bytes\": \"#{@size_in_bytes}\", \"files\" : #{files} \}"
  end
end

#returns DirectoryDefinition object
def define_folder(folder_path)
  curr_dir = DirectoryDefinition.new(folder_path, 0, [])
  
  search_string = File.join(folder_path,'*')
  puts("search string: #{search_string}")
  
  wd_files = Dir.glob(search_string)
    
  wd_files.each{ |file|
    
    if File.directory?(file) && File.extname(file) != '.app'
      sub_folder = define_folder(file)
      curr_dir.file_list << sub_folder
      curr_dir.size_in_bytes += sub_folder.size_in_bytes
    else
      sub_file = FileDefinition.new(file)
      curr_dir.size_in_bytes += sub_file.size_in_bytes
      curr_dir.file_list << sub_file
    end
  }
  return curr_dir
end

dir_path = ''
if ARGV[0].nil? || !File.directory?(ARGV[0])
  puts("directory required.")
  return
end

dir_path = ARGV[0]

main_dir = define_folder(dir_path)
size = main_dir.size_in_bytes
puts("directory info:")
puts("path: #{main_dir.path}")
puts("size: #{get_size_string(size)} (#{size} B)")
puts("files: #{main_dir.file_list.length}")

#main_dir.file_list.each { |file|
#  puts("\t#{file.path} (#{file.get_size_string()})")
#}

#puts("json:")
puts("writing json to ./file_structure.json")
File.open("file_structure.json", 'w') {|f| f.write(main_dir.to_json()) }
#puts(main_dir.to_json())
