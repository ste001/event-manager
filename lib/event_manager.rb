require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

template_letter = File.read "form_letter.html"

def clean_zipcode zipcode
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_cellphone_numbers cellphone
  if (cellphone.length == 10)
    cellphone
  elsif (cellphone.length == 11 && cellphone[0]="1")
    cellphone = cellphone.to_s.ljust(10)
  else
    "Bad number"
  end    
end

def legislators_by_zipcode zip
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")
  filename = "output/thanks_#{id}.html"
  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def create_thank_you_letters (contents, template_letter, erb_template)
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    cellphone = clean_cellphone_numbers(row[:homephone])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)
    save_thank_you_letters(id,form_letter)
  end
end

def peak_hours contents
  peak_hours = { "0" => 0, "1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0, "6" => 0,
    "7" => 0, "8" => 0, "9" => 0, "10" => 0, "11" => 0, "12" => 0,
    "13" => 0, "14" => 0, "15" => 0, "16" => 0, "17" => 0, "18" => 0,
    "19" => 0, "20" => 0, "21" => 0, "22" => 0, "23" => 0 }
  contents.each do |row|
    regdate = row[:regdate]
    hour = DateTime.strptime(regdate, '%m/%d/%y %H:%M').hour.to_s
    peak_hours[hour] += 1
  end
  max = peak_hours.values.max
  Hash[peak_hours.select { |k, v| v == max}].keys
end

def peak_days contents
  peak_days = { "0" => 0, "1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0, "6" => 0 }
  contents.each do |row|
    regdate = row[:regdate]
    wDay = DateTime.strptime(regdate, '%m/%d/%y %H:%M').wday.to_s
    peak_days[wDay] += 1
  end
  max = peak_days.values.max
  Hash[peak_days.select { |k, v| v == max}].keys
end

def number_to_word day
  case day
  when "0"
    "Monday"
  when "1"
    "Tuesday"
  when "2"
    "Wednesday"
  when "3"
    "Thursday"
  when "4"
    "Friday"
  when "5"
    "Saturday"
  when "6"
    "Sunday"
  else
    "Day not valid!"
  end
end

puts "EventManager Initialized!\n"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

puts "Actions:\n"
puts "1. Create Thank You letters"
puts "2. See peak hours of user registrations"
puts "3. See peak days of user registrations"

input = gets.chomp
case input
when "1"
  create_thank_you_letters(contents, template_letter, erb_template)
  puts "Letters created and saved!"
when "2"
  hours = peak_hours(contents).join(", ")
  puts "Peak hour(s): #{hours}"
when "3"
  days = peak_days(contents)
  puts "Peak day(s): #{days.map {|i| number_to_word i}.join(", ")}"
else
  puts "No action defined for that input!"
end