html_file = './tweeters-2013-09-13.html'
json_crafts = IO.read './crafts-2013-09-13.json'

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

File.open(html_file, 'a') { |file| file.write "<html><body>\n" }
next_place = tweeters.first[:place]
File.open(html_file, 'a') { |file| file.write "<h2>#{next_place}</h2>" }
tweeters.each do |tweeter|
  if tweeter[:href]
    place = tweeter[:place]
    screen_name = tweeter[:href].to_s.split('/').last
    line = "[#{tweeter[:state]}] [#{tweeter[:city]}]: <A href='#{tweeter[:href]}' target='t'>#{screen_name}</A><br>\n"
    File.open(html_file, 'a') { |file| file.write line }
    unless place.eql? next_place
      File.open(html_file, 'a') { |file| file.write "<h2>#{place}</h2>" }
      next_place = place
      File.open(html_file, 'a') { |file| file.write "place = #{place}, next_place = #{next_place} eq = #{place.eql? next_place}" }
    end
  end
end

places = tweeters.map {|tweeter| tweeter[:place]}
places = places.uniq

File.open(html_file, 'a') { |file| file.write "<hr>\n<h2>#{places.count} Places</h2>" }
places.each do |place|
  File.open(html_file, 'a') { |file| file.write "#{place}<br>" }
end
File.open(html_file, 'a') { |file| file.write "</body></html>" }
