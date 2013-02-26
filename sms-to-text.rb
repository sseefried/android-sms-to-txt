require 'rubygems'
require 'sqlite3'



YOU = "Sean"

SMS_DB = "mmssms.db"
CONTACTS_DB = "contacts.db"

(puts "#{SMS_DB} does not exist"; exit 1)      unless File.exist?(SMS_DB)
(puts "#{CONTACTS_DB} does not exist"; exit 1) unless File.exist?(CONTACTS_DB)

##########################################
## Constants

ADDRESS, PERSON, DATE, TYPE, BODY = 0,1,2,3,4

NAME=1

IS_REPLY = 2 # A magic number used in the 'type' field of the 'sms' table

########################################

db = SQLite3::Database.new(SMS_DB)
smses = db.execute("select address, person, date, type, body from sms;")

db = SQLite3::Database.new(CONTACTS_DB)
rows = db.execute("select _id, display_name from raw_contacts;")

people = {}
rows.each do |row|
  people[row[0].to_i] = row[NAME]
end

threads = {}

smses.each do |sms|
  key = sms[ADDRESS] # .to_s.gsub(/\+61/,"0")
  threads[key] ||= { :messages => []}
  person_id = sms[PERSON].to_i
  if person_id != 0
    threads[key][:name] = people[person_id]
  end
  threads[key][:messages] << { :time => Time.at(sms[DATE].to_i/1000), :body => sms[BODY],
                               :reply => sms[TYPE] == IS_REPLY}
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


