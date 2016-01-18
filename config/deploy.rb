# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'election-2016'
set :repo_url, 'ssh://git@github.com/huffpostdata/election-2016'

set :deploy_to, '/opt/election-2016'
set :linked_dirs, fetch(:linked_dirs, []).push('tmp', 'cache')

desc 'Set new AP API key'
task :reset_env do
  ask(:ap_api_key, nil)
  on roles(:all) do |host|
    execute "echo AP_API_KEY='#{fetch(:ap_api_key)}' > #{shared_path}/env"
    execute "echo AWS_REGION=us-east-1 >> #{shared_path}/env"


    # FIXME remove AP_TEST. We use it because AP gives bad candidate data
    # prior to 2016-01-31, but we want to render pages before that date. But
    # AP_TEST=true doesn't actually solve that problem. Really, we need to
    # maintain our own list of candidates somewhere.
    execute "echo AP_TEST=true" >> #{shared_path}/env"
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

  after :finished, :start_or_restart do
    on roles(:all) do |host|
      execute("#{deploy_to}/current/script/run-production-command exit || true")

      execute("(cd #{deploy_to}/current && bash -c '/usr/bin/env $(cat #{shared_path}/env | xargs) script/production-server >> #{shared_path}/production.log 2>&1 &')")

      execute("echo Started server")
    end
  end
end
