
require 'dashing'
require 'yaml'

$global_config = YAML.load_file('./config/integrations.yml') || {}

configure do
  set :auth_token, 'NOT_PROTECTED'
  set :default_dashboard, 'cycle'
  helpers do
    def protected!
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
