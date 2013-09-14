require "active_support/core_ext"

HTML_DIR = './tweeters-2013-09-15'
json_crafts = IO.read './crafts-2013-09-15.json'

def html_file(state)
  "#{HTML_DIR}/#{state}.html"
end

crafts = JSON.parse json_crafts

tweeters = crafts.map do |craft|
  place = craft['address'].to_s.squish
  if place
    place[',,'] = ',' if place[',,']
    city, *state = place.split(',')
    city = city.squish if city
    state = state.join(', ').squish if state
    place = "#{city.squish.downcase.capitalize}, #{state.squish.upcase}"
    { place: place, state: state, city:city , href: craft['hrefs']['twitter'] }
  end
end

tweeters.sort! do |a,b|
  score = a[:state] <=> b[:state]
  score = a[:city] <=> b[:city] if 0.eql? score
  score
end

tweeters_in_states = Hash.new {|hash, key| hash[key] = [ ]}
tweeters.each do |tweeter|
  tweeters_in_states[tweeter[:state]] << tweeter
end


places = tweeters.map {|tweeter| tweeter[:place]}
places = places.uniq

File.open(html_file('1-places'), 'w') do |file_places|
  file_places.write "<html><body>\n<h2>#{places.count} Places</h2>\n"
  places.each do |place|
    file_places.write "<div>#{place}</div>\n"
  end
  file_places.write "</body></html>\n"
end

states = tweeters.map {|tweeter| tweeter[:state]}
states = states.uniq

File.open(html_file('0-states'), 'w') do |file_states|
  file_states.write "<html><body>\n<h2>#{states.count} States</h2>\n"
  states.each do |state|
    file_states.write "<div><a href='#{state}.html'>#{state}</a></div>\n"
  end
  file_states.write "</body></html>\n"
end

def follow_button_html(screen_name)
  "<iframe style='min-width:300px; height:20px;' allowtransparency='true' frameborder='0' scrolling='no' src='http://platform.twitter.com/widgets/follow_button.html?screen_name=#{screen_name}&show_count=true&show_screen_name=true'></iframe>"
end

tweeters_in_states.each do |state, state_tweeters|
  File.open(html_file(state), 'w') do |file_state|
    file_state.write "<html><body>\n<h1>#{state}</h1>\n"
    next_place = state_tweeters.first[:place]
    file_state.write "<h2>#{next_place}</h2>\n"
    state_tweeters[0..10].each do |tweeter|
      if tweeter[:href]
        place = tweeter[:place]
        screen_name = tweeter[:href].to_s.split('/').last
        twitter_link = "<A href='#{tweeter[:href]}' target='t'>#{screen_name}</A>"
        line = "<div style='height:24px;line-height:24px; font-size: 16px'>\n"
        line = "#{line}  [#{tweeter[:state]}] [#{tweeter[:city]}] \n"
        line = "#{line}  #{follow_button_html(screen_name)}\n"
        line = "#{line}  - #{twitter_link}\n"
        line = "#{line}</div>\n"
        file_state.write line
        unless place.eql? next_place
          file_state.write "<h2>#{place}</h2>\n"
          next_place = place
        end
      end
    end
    file_state.write "</body></html>\n"
  end
end

# next_place = tweeters.first[:place]
# File.open(html_file(tweeters.first[:state]), 'a') { |file| file.write "<h2>#{next_place}</h2>\n" }

# tweeters[0..10].each do |tweeter|
#   if tweeter[:href]
#     state = tweeter[:state]
#     place = tweeter[:place]
#     screen_name = tweeter[:href].to_s.split('/').last
#     twitter_link = "<A href='#{tweeter[:href]}' target='t'>#{screen_name}</A>"
#     follow_button_html = "<iframe allowtransparency='true' frameborder='0' scrolling='no' src='http://platform.twitter.com/widgets/follow_button.html?screen_name=#{screen_name}&show_count=true&show_screen_name=true' style='min-width:300px; height:20px;'></iframe>"
#     line = "<div style='height:24px;line-height:24px; font-size: 16px'>\n"
#     line += "  [#{tweeter[:state]}] [#{tweeter[:city]}] \n"
#     line += "  #{follow_button_html}\n"
#     line += "  - #{twitter_link}\n"
#     line += "</div>\n"
#     puts "writing to #{state}"
#     File.open(html_file(state), 'a') do |file|
#       file.write line
#       unless place.eql? next_place
#         file.write "<h2>#{place}</h2>\n" }
#         next_place = place
#       end
#     end
#   end
# end
# states.each do |state|
#   File.open(html_file(state), 'a') { |file| file.write "</body></html>\n" }
# end
