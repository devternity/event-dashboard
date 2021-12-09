# encoding: utf-8

require 'yaml'

###########################################################################
# Job's body.
###########################################################################

$photo_position = 0
$photo_index = 0

$global_config = YAML.load_file('./config/integrations.yml') || {}
$photo_config = YAML.load_file('./config/photos.yml') || {}
$photos = $photo_config['photos'] || [ '/assets/splash2018.png' ]

def send_photo_update()
  next_position = 'photo' + (1 + ($photo_position % 5)).to_s
  next_index = $photo_index % $photos.length
  next_photo = $photos[next_index]
  send_event(next_position, new_image: next_photo)
  $photo_index = $photo_index + 1
  $photo_position = $photo_position + 1
end

SCHEDULER.in '1s' do |job|
  5.times { send_photo_update() }
end

SCHEDULER.every '10s', :first_in => '6s' do |job|
  send_photo_update()
end



