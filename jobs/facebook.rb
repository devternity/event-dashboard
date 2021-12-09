# encoding: utf-8

require 'yaml'
require 'koala'
require 'active_support/time'

###########################################################################
# Load configuration parameters.
###########################################################################

$global_config = YAML.load_file('./config/integrations.yml') || {}
$filter_config = YAML.load_file('./config/filters.yml') || {}
$fb_page = URI::encode($global_config['facebook_page'] || "DevTernity")
$graph = Koala::Facebook::API.new($global_config['facebook_access_token'], $global_config['facebook_app_secret'])

def page_stats(page_name)
  info = $graph.get_object(
    page_name,
    { fields: ['fan_count', 'new_like_count', 'rating_count', 'country_page_likes', 'talking_about_count', 'were_here_count', 'checkins'] },
    { :use_ssl => true }
  )
  {
    likes: info['fan_count'],
    checkins: info['checkins'],
    were_here: info['were_here_count'],
    talking_about: info['talking_about_count']
  }
end

def page_ratings(page_name)
  info = $graph.get_object(
    page_name,
    { fields: ['ratings'] },
    { :use_ssl => true }
  )
  ratings = info['ratings']['data']
    .select { |r| 
       r['rating'] == 5 && 
      !r['review_text'].nil? && 
      !r['review_text'].empty? &&
       r['review_text'].length < 220
    }.select { |r|
      !$filter_config['facebook_exclude_terms'].any? { |term| 
        r['review_text'].downcase.include?(term)  
      }
    }
  ratings.each { |r| 
    r['time'] = r['created_time'].in_time_zone('Europe/Riga').strftime("%Y-%m-%d") 
  }
  {
    ratings: ratings
  }
end


###########################################################################
# Job's schedules.
###########################################################################

SCHEDULER.every '15m', :first_in => 0 do |job|
  stats = page_stats($fb_page)
  send_event('facebook_likes', current: stats[:likes])
  send_event('facebook_checkins', current: stats[:checkins])
  send_event('facebook_were_here_count', current: stats[:were_here])
  send_event('facebook_talking_about_count', current: stats[:talking_about])
end

SCHEDULER.every '15m', :first_in => 0 do |job|
  ratings = page_ratings($fb_page)
  send_event('facebook_ratings', ratings: ratings[:ratings])
end

