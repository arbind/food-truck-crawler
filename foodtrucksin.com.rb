require 'open-uri'
require 'nokogiri'
require "active_support/core_ext"

require './string.rb'
require './web.rb'

def foodtruckme_url(id)
  endpoint = 'http://foodtrucksin.com/node'
  "#{endpoint}/#{id}"
end

json_file = 'crafts.json'

css_selector={}
css_selector[:name] = 'h1'
css_selector[:phone] = '.field-name-field-phone .field-item'
css_selector[:address] = '.field-name-city-and-state .field-item'
truck_ids =(7385..11327).to_a
event_ids =(11339..11497).to_a
puts "#{truck_ids.count} trucks"
puts "#{event_ids.count} events"

crafts = []

File.open(json_file, 'a') { |file| file.write('[') }
ids = truck_ids
ids.each_with_index do |truck_id, idx|
  craft = {}
  hrefs = {}
  craft[:hrefs] = hrefs
  site = Web.site foodtruckme_url(truck_id)

  [:name, :phone, :address].each do |selector|
    element = site.select_first(css_selector[selector])
    craft[selector] = element.content if element
  end

  links = site.links
  links.reject!{|link| link.to_s.strip.length.eql? 0 or link.match /foodtrucksin/i or !link.match /^http/i }

  links.reject! do |link|
    action = :keep
    [:yelp, :twitter, :facebook].each do |provider|
      if link.match /#{provider}/
        hrefs[provider] = link
        action = :skip
      end
    end
    action.eql? :skip
  end

  hrefs[:website] = links.first if links.length.eql? 1
  crafts << craft
  puts craft
  output = "\n#{craft.to_json}"
  output = "#{output}," unless idx.eql? (ids.count-1)
  File.open(json_file, 'a') { |file| file.write(output) }
end
File.open(json_file, 'a') { |file| file.write("\n]") }
