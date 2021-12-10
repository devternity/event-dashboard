# encoding: utf-8

require 'json'
require 'net/http'
require 'open-uri'
require 'active_support/time'
require 'uri'
require 'yaml'
require 'date'

###########################################################################
# Job's body.
###########################################################################

$global_config = YAML.load_file('./config/integrations.yml') || {}

###########################################################################
# Job's module.
###########################################################################

module Devternity 

  def to_min(time_code)
    return (time_code / 100) * 60 + time_code % 100
  end

  def type2image(type, title)  
    base_path = '/assets/events/'
    if title.include? "Lunch"
      return base_path + 'dash_lunch.png'
    elsif title.include? "Opening"
      return base_path + 'dash_opening.png'
    elsif title.include? "Final"
      return base_path + 'dash_finish.png'
    elsif title.include? "Beer"
      return base_path + 'beer2.png'
    elsif type == "start"
      return base_path + 'dash_start.png'
    elsif type == "break"
      return base_path + 'dash_break.png'
    end
    return ''
  end
  
  def type2room(type, title)  
    if title.include? "Lunch"
      return 'SLACK BREAK'
    elsif title.include? "Beer"
      return ' '
    elsif title.include? "Opening"
      return 'TRACK '
    elsif title.include? "Final"
      return 'TRACK '
    elsif type == "start"
      return 'SLACK BREAK'
    elsif type == "break"
      return 'SLACK BREAK'
    end
    return 'TRACK '
  end
  
  def send_schedule_updates(global_config, job, &block)
    current_time = Time.now.in_time_zone('Europe/Riga')
    current_min  = current_time.hour * 60 + current_time.min
    schedule     = JSON.parse(open(global_config['devternity_data_file']) { |f| f.read }).first['program'].find { |e| e['event'] == 'keynotes' }['schedule']
    time_slots   = schedule.find { |time_slot| time_slot['plumber'] != true }.map do |time_slot|
      { 
        :time      => time_slot['time'], 
        :time_code => time_slot['time'].split(':').join('').to_i, 
        :name      => time_slot['name'],
        :title     => time_slot['title'],
        :type      => time_slot['type'],
        :room_name => type2room(time_slot['type'], time_slot['title']),
        :img       => time_slot['img'].nil? ? type2image(time_slot['type'], time_slot['title']) : 'https://devternity.com/' + time_slot['img']
      }
    end
    future_slots     = time_slots.select { |time_slot| to_min(time_slot[:time_code]) > current_min }  
    past_slots       = time_slots.select { |time_slot| to_min(time_slot[:time_code]) <= current_min }
    past_time_code   = past_slots.size > 0 ? past_slots.last[:time_code] : 0
    future_time_code = future_slots.size > 0 ? future_slots.first[:time_code] : time_slots.last[:time_code]
    next_slot_start  = to_min(future_time_code)
    prev_slot_end    = to_min(past_time_code)
    slot_duration    = next_slot_start - prev_slot_end
    passed_mins      = current_min - prev_slot_end
    time_code        = future_time_code
    if (slot_duration > 20 && passed_mins < 15) || (slot_duration <= 20 && passed_mins < 5)
      time_code      = past_time_code
    end
    current_slots    = time_slots.select { |slot| slot[:time_code] == time_code }
    if current_slots && current_slots.size > 0
      track1 = current_slots[0]
      track2 = current_slots.size > 1 ? current_slots[1].clone : current_slots[0].clone
      track3 = current_slots.size > 2 ? current_slots[2].clone : current_slots[0].clone
      if track1[:room_name].start_with? 'TRACK '
        track1[:room_name] += '1'
      end
      if track2[:room_name].start_with? 'TRACK '
        track2[:room_name] += current_slots.size == 1 ? '1' : '2'
      end
      if track3[:room_name].start_with? 'TRACK '
        track3[:room_name] += current_slots.size == 1 ? '1' : '3'
      end
      block.call('track1', session: track1)
      block.call('track2', session: track2)
      block.call('track3', session: track3)
    end
  end
  
end  

include Devternity

if defined? SCHEDULER
  SCHEDULER.every '3m', :first_in => 0 do |job|
    global_config = YAML.load_file('./config/integrations.yml')
    Devternity.send_schedule_updates global_config, job do |eventName, eventData| 
      send_event(eventName, eventData)
    end
  end
end

