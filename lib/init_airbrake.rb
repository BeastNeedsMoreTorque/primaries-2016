if ENV['AIRBRAKE_PROJECT_KEY'] && ENV['AIRBRAKE_PROJECT_ID']
  require 'airbrake-ruby'
  Airbrake.configure do |c|
    c.project_key = ENV['AIRBRAKE_PROJECT_KEY']
    c.project_id = ENV['AIRBRAKE_PROJECT_ID']
  end
  $stderr.puts "Using Airbrake project ID #{ENV['AIRBRAKE_PROJECT_ID']}"
end
