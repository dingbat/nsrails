require 'bundler/capistrano'

set :application,   'nsrails'
set :repository,    "ssh://git@github.com:dingbat/#{application}.git"
set :passenger_port,'8080'

task :production do
  role :web, 'nsrails.com'
  role :app, 'nsrails.com'
  role :db,  'nsrails.com', :primary => true
  set :deploy_role, 'production'
  set :rails_env, 'production'
  set :branch, 'master'
end

set :keep_releases, 5

set :user, 'dhassin'
set :use_sudo, false

set :scm,           :git
set :branch,        'master'

set :deploy_to,     "/home/#{user}/rails/#{application}"
set :deploy_via,    :remote_cache

# This will execute the Git revision parsing on the *remote* server rather than locally
set :real_revision, 			lambda { source.query_revision(revision) { |cmd| capture(cmd) } }

after "deploy:symlink", "deploy:symlink_configs"

namespace :deploy do
  task :symlink_configs, :roles => :app, :except => {:no_symlink => true} do
    run <<-CMD
      cd #{release_path} && ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml && rake tmp:clear && rake tmp:cache:clear 
    CMD
  end
  
  task :start, :roles => :app do
    run "rvm rvmrc trust #{current_path}; cd #{current_path}; rvmsudo passenger start -d -p #{passenger_port} -e production --user=ihassin"
    #run "touch #{current_release}/tmp/restart.txt"
  end
 
  task :stop, :roles => :app do
    run "rvm rvmrc trust #{current_path}; cd #{current_path}; rvmsudo passenger stop -p #{passenger_port}"
  end
 
  task :restart, :roles => :app do
    stop
    start
  end
  
end

namespace :rake do
 desc "Run a task on a remote server. Excample: cap production rake:invoke task=my_task"
 task :invoke do
   run("cd #{deploy_to}/current; rake RAILS_ENV=production")
 end
end


Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
  $: << File.join(vendored_notifier, 'lib')
end
