#
# Utility script: restore default permissions for files and directories
#

entries = Dir.glob("./**/*").sort - [File.expand_path(__FILE__)]

entries.each do |entry|
  puts entry
  if File.directory?(entry)
    puts File.chmod(0755, entry)
  else
    if entry =~ /\/script\//
      puts File.chmod(0744, entry)
    else
      puts File.chmod(0644, entry)
    end
  end
end