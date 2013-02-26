require 'rubygems'
require 'mktemp'
require 'csv'

YOU = "Sean"
# HUGE HACK. Need to choose a quote char that doesn't appear in any of the texts!
QUOTE_CHAR = "`"

########################################

file = MkTemp::tmpnam("smses.csvXXXX")
system(%Q{(echo "select * from sms;" | sqlite3 mmssms.db) > #{file}})

smses = []
CSV.foreach(file, {:col_sep => "|", :quote_char => QUOTE_CHAR}) do |row|
  smses << row
end
File.unlink(file)

file = MkTemp::tmpnam("people.csvXXXX")
system(%Q{(echo "select * from raw_contacts;" | sqlite3 contacts.db) > #{file}})

NAME=15

people = {}
CSV.foreach(file, {:col_sep => "|", :quote_char => QUOTE_CHAR}) do |row|
  people[row[0].to_i] = row[NAME]

end
File.unlink(file)


TO=2
PERSON=3
TIME=4
DATE=4
TYPE=9
BODY=12
IS_REPLY = "2"

threads = {}

smses.each do |sms|
  key = sms[TO].to_s.gsub(/\+61/,"0")
  threads[key] ||= { :messages => []}
  person_id = sms[PERSON].to_i
  if person_id != 0
    threads[key][:name] = people[person_id]
  end
  threads[key][:messages] << { :time => Time.at(sms[TIME].to_i/1000), :body => sms[BODY], :reply => sms[TYPE] == IS_REPLY}
end

threads = threads.to_a
threads.each { |k,t| t[:messages].sort_by! {|m| m[:time]}}
threads.sort_by! {|k,t| t[:messages].first[:time]}

threads.each do |k,t|
  first_time = t[:messages].first[:time].strftime("%d %b %Y")
  if t[:name]
    puts "=== #{YOU} and #{t[:name]} (starting on #{first_time}) ==="
    t[:messages].each do |m|
      printf "--\n%s\n", m[:time].strftime("%d %B %Y %H:%M")
      printf("From: %s\n", m[:reply] ? YOU : t[:name])
      printf "--\n%s\n", m[:body]
      puts
    end
  end
end


