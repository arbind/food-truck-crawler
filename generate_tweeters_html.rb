require "active_support/core_ext"

HTML_DIR = './tweeters-2013-09-15'
json_crafts = IO.read './crafts-2013-09-15.json'

def html_file_name(state, idx)
  name = state
  name = "#{name}-#{idx}" if idx > 0
  "#{name}.html"
end


def html_file(state, idx=0)
  "#{HTML_DIR}/#{html_file_name(state, idx)}"
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
    { place: place, state: state, city:city , href: craft['hrefs']['twitter'], name: craft['name'] }
  end
end

tweeters.sort! do |a,b|
  score = a[:state] <=> b[:state]
  score = a[:city] <=> b[:city] if 0.eql? score
  score
end

tweeters_in_states = Hash.new {|hash, key| hash[key] = [ ]}
tweeters.each do |tweeter| # map tweeters to state
  if tweeter and tweeter[:href] # if they have a twitter_href map to state
    tweeters_in_states[tweeter[:state]] << tweeter
  end
end

places = tweeters.map {|tweeter| tweeter[:place]}
places = places.uniq

states = tweeters.map {|tweeter| tweeter[:state]}
states = states.uniq

states.sort! do |a,b|
  tweeters_in_states[b].count <=> tweeters_in_states[a].count
end

tweeters_in_states.each do |state, tweeters|
  if tweeters.count.eql? 0  # prune empty states
    states.delete(state)
    tweeters_in_states.delete(state)
  else # batches of 50
    tweeters_in_states[state] = tweeters.each_slice(50).to_a
  end
end

File.open(html_file('1-places'), 'w') do |file_places|
  file_places.write "<html><body>\n<h2>#{places.count} Places</h2>\n"
  places.each do |place|
    file_places.write "<div>#{place}</div>\n"
  end
  file_places.write "</body></html>\n"
end

File.open(html_file('0-states'), 'w') do |file_states|
  file_states.write "<html><body>\n<h2>#{states.count} States</h2>\n"
  states.each do |state|
    tweeters_in_states[state].each_with_index do |batch, idx|
      count = batch.count
      file_states.write "<div><a href='#{html_file_name(state, idx)}'>#{state}-#{idx+1} (#{count})</a></div>\n"
    end
  end
  file_states.write "</body></html>\n"
end

def follow_button_html(screen_name)
  "<iframe style='min-width:300px; height:20px;' allowtransparency='true' frameborder='0' scrolling='no' src='http://platform.twitter.com/widgets/follow_button.html?screen_name=#{screen_name.squish}&show_count=true&show_screen_name=true'></iframe>"
end

states.each do |state|
  batches = tweeters_in_states[state]
  batches.each_with_index do |state_tweeters, idx|
    File.open(html_file(state, idx), 'w') do |file_state|
      file_state.write "<html><body>\n<h1>#{state}</h1>\n"
      next_place = state_tweeters.first[:place]
      file_state.write "<h2>#{next_place}</h2>\n"
      state_tweeters.each_with_index do |tweeter, count|
        if tweeter[:href]
          place = tweeter[:place]
          unless place.eql? next_place
            file_state.write "<h2>#{place}</h2>\n"
            next_place = place
          end
          screen_name = tweeter[:href].to_s.split('/').last
          twitter_link = "<A href='#{tweeter[:href]}' target='t'>#{screen_name}</A>"
          line = "<div style='height:24px;line-height:24px; font-size: 16px'>\n"
          line = "#{line}  #{idx+1}.#{count+1}. [#{tweeter[:state]}] [#{tweeter[:city]}] \n"
          line = "#{line}  #{follow_button_html(screen_name)}\n"
          line = "#{line}  - #{twitter_link}\n"
          line = "#{line}</div>\n"
          file_state.write line
        end

      end
      file_state.write "</body></html>\n"
    end
  end
end