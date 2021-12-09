# encoding: utf-8

require 'active_support/core_ext/enumerable'
require 'active_support/time'
require 'json'
require 'yaml'
require 'date'
require 'time'
require 'firebase'
require 'net/http'
require 'open-uri'
require 'uri'

###########################################################################
# Load configuration parameters.
###########################################################################

$global_config = YAML.load_file('./config/integrations.yml') || {}
$firebase_json = File.open('./config/firebase-voting.json') { |file| file.read }
$firebase_config = JSON.parse($firebase_json)
$base_url = "https://#{$firebase_config['project_id']}.firebaseio.com/"
$firebase_client = Firebase::Client.new($base_url, $firebase_json)

def now
  Time.now.in_time_zone('Europe/Riga')
end

def votes_for_date(date = now())
  from = date.in_time_zone('Europe/Riga').beginning_of_day
  to   = date.in_time_zone('Europe/Riga').end_of_day
  response = $firebase_client.get("votes", { 'orderBy' => '"created"', 'startAt' => from.to_i, 'endAt' => to.to_i })
  raise "DT error #{response.code} (#{response.body})" unless response.success?
  response.body || []
end

###########################################################################
# Job's schedules.
###########################################################################

SCHEDULER.every '15m', :first_in => 0 do |job| 

  send_event('greens', { current: (votes_for_date(now()) || []).length }) 

end
