#!/usr/bin/env ruby

require 'gruff'

bins = 6
name_length = 15
dimensions = '900x450'

SIGNAGE = {
  :colors => [
    #'#a9dada', # blue
    '#aedaa9', # green
    '#daaea9', # peach
    '#dadaa9', # yellow
    '#a9a9da', # dk purple
    '#daaeda', # purple
    '#dadada', # grey
    '#6886B4', # blue
    '#D1695E', # red
    '#8A6EAF', # purple
    '#EFAA43', # orange
    'white',
  ],
  :marker_color => '#aea9a9', # Grey
  :font_color => 'white',
  :background_colors => 'black'
}

def sumbins(set)
  sum = 0
  set.each do |man|
      sum += man[:count]
  end

  return { :name => '[other]', :count => sum }
end

input = ARGF.readlines

datasets = []
input.each do |line|
  m = line.match(/^(\d+)\s+(.*)$/)

  man = {}
  man[:count] = m[1].to_i
  man[:name]  = m[2]

  man[:name] = man[:name][0, name_length]

  datasets.push man
end

plot = []
# take the top X vendors and bin all remaining into other
if datasets.size > bins
  plot = datasets[0 .. bins]
  plot.push sumbins(datasets[bins .. -1])
else
  plot = vendors
end

g = Gruff::Pie.new(dimensions)
#g.title = 'Top Wi-Fi device manufacturers'
plot.each do |man|
  g.theme = SIGNAGE
  g.data(man[:name], man[:count])
end

#g.write('wifi_pie.png')
g.write('/home/jhoblitt/apwatch/images/wifi_pie.png')
