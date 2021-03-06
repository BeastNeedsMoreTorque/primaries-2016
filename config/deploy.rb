# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'election-2016'
set :repo_url, 'ssh://git@github.com/huffpostdata/election-2016'

set :deploy_to, '/opt/election-2016'
set :linked_dirs, fetch(:linked_dirs, []).push('tmp', 'cache', 'cache-by-date')

desc 'Set new AP API key'
task :reset_env do
  on roles(:all) do |host|
    execute "echo Existing environment: && cat #{shared_path}/env"
  end

  ask(:s3_bucket, nil)
  ask(:ap_api_key, nil)
  ask(:asset_host, nil)
  ask(:facebook_app_id, nil)
  ask(:airbrake_project_id, nil)
  ask(:airbrake_project_key, nil)
  ask(:last_date, '2016-07-01')

  on roles(:all) do |host|
    execute "echo AP_API_KEY='#{fetch(:ap_api_key)}' > #{shared_path}/env"
    execute "echo S3_BUCKET='#{fetch(:s3_bucket)}' >> #{shared_path}/env"
    execute "echo ASSET_HOST='#{fetch(:asset_host)}' >> #{shared_path}/env"
    execute "echo FACEBOOK_APP_ID='#{fetch(:facebook_app_id)}' >> #{shared_path}/env"
    execute "echo AIRBRAKE_PROJECT_ID='#{fetch(:airbrake_project_id)}' >> #{shared_path}/env"
    execute "echo AIRBRAKE_PROJECT_KEY='#{fetch(:airbrake_project_key)}' >> #{shared_path}/env"
    execute "echo AWS_REGION=us-east-1 >> #{shared_path}/env"
    execute "echo LAST_DATE='#{fetch(:last_date)}' >> #{shared_path}/env"
  end
end

desc 'Ensure the AP API key exists'
task :ensure_env do
  results = on roles(:all) do |host|
    test("[ -f #{shared_path}/env ]")
  end.map(&:value)
  if results.include?(false)
    invoke :reset_env # only works when there's one server. Like all elections-2016.
  end
end

desc 'Refresh AP results for a certain date'
task :tell_server do
  if !ENV['command']
    raise %q{You must specify a command. e.g., "cap staging tell_server command='poll_dates 2016-02-01'}
  end
  on roles(:all) do
    execute "#{deploy_to}/current/script/run-production-command #{ENV['command']}"
  end
end

# Janky namespaces. https://github.com/capistrano/capistrano/issues/1543
namespace :deploy do
  namespace :symlink do
    after :shared, :ensure_env_hack do
      invoke :ensure_env
    end
  end

  desc 'Restart the server (and upload pages ASAP), without a git checkout'
  after :finished, :start_or_restart do
    on roles(:all) do |host|
      execute("#{deploy_to}/current/script/run-production-command exit || true")

      execute("(cd #{deploy_to}/current && bash -c '/usr/bin/env $(cat #{shared_path}/env | xargs) script/production-server >> #{shared_path}/production.log 2>&1 &')")

      execute("echo Started server")
    end
  end
end
