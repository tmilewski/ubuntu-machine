namespace :mediamountain do
  namespace :dirmon do
    desc 'Installs the dirmon script in ~/bin and adds it to the crontab'
    task :install, :roles => :app do
      install_script
      add_dirmon_to_cron
    end

    desc 'Installs the dirmon script in ~/bin'
    task :install_script, :roles => :app do
      run "mkdir -p bin"
      put render("dirmon", binding), "bin/dirmon"
      run "chmod +x bin/dirmon"
    end

    desc 'adds the dirmon calls to the crontab'
    task :add_dirmon_to_cron, :roles => :app do
       add_to_crontab('/home/yoadmin/bin/dirmon ~mediama/ftp 1 rm','0,15,30,45 * * * *')
       add_to_crontab('/home/yoadmin/bin/dirmon ~mediamb/ftp 1 rm','5,20,35,50 * * * *')
       add_to_crontab('/home/yoadmin/bin/dirmon ~mediamc/ftp 1 rm','10,25,40,55 * * * *')
    end
  end

  desc 'Installs the primary and secundary pubkeys defined in ssh_secundary_keys to allow access to the root user'
  task :add_root_pubkey_access do
    dir = '~root/.ssh'
    file = File.join(dir,'authorized_keys2')
    sudo "mkdir -p #{dir}"
    sudo "chown -R root:root #{dir}"
    sudo "touch #{file}"
    sudo "chmod 700 #{dir} && sudo chmod 0600 #{file}"

    keys = ([*ssh_secundary_keys] + [*ssh_options[:keys]]).uniq
    keys.each do |key|
      key = File.read("#{key}.pub")
      sudo_add_to_file(file,key)
    end
  end

  desc "Installs libxml2-dev library, libxml-ruby gem and Narnach's libxml-rails"
  task :install_libxml do
    sudo "aptitude install -y libxml2-dev"
    sudo "gem install libxml-ruby"
    run "if test -x libxml_rails; then cd libxml_rails && git checkout master && git pull; else git clone git://github.com/Narnach/libxml_rails.git; fi"
    run "cd libxml_rails && git checkout 0.0.2.4 && rake install"
  end

  desc "Generates and/or outputs ssh pubkey"
  task :ssh_pubkey do
    run_and_watch_prompt "if test -s .ssh/id_rsa.pub; then cat .ssh/id_rsa.pub; else ssh-keygen -t rsa && cat .ssh/id_rsa.pub; fi", [/Enter file in which to save the key/,/Enter passphrase/,/Enter same passphrase/,/Overwrite/]
    puts "copy the above key to gitosis-admin as #{hostname}.pub and add #{hostname} to the members of the skiparks group"
    puts "example: scp #{hostname}:.ssh/id_rsa.pub ~/Development/yoMedia/gitosis-admin/keydir/#{hostname}.pub"
  end

  desc "Clones sensors.git and crontabs it"
  task :install_sensors do
    ssh_pubkey
    run_and_watch_prompt "if test -x sensors; then cd sensors && git checkout master && git pull; else git clone yomediagit:sensors.git; fi", /Are you sure you want to continue connecting/
    run "cd sensors && bin/add_to_cron"
  end

  desc "Uploads media_monitor start/stop executables for use with Monit"
  task :upload_mediamon_executables do
    upload("../bin/mediamon_start","bin/", :via => :scp, :recursive => false)
    upload("../bin/mediamon_stop","bin/", :via => :scp, :recursive => false)
    run "chmod a+x ~/bin/mediamon_*"
  end
end