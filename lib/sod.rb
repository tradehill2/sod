require 'rubygems'
require 'net/scp'
require 'yaml'

module Sod
  def self.provision(host)
    ssh_config = Net::SSH.configuration_for host
    puts "You need to put some happy in ~/.ssh/config for #{host}" or exit(1) unless ssh_config[:user] #SORRY
    config = YAML.load(File.read("./Sodfile"))["production"]
    Net::SSH.start(ssh_config[:hostname], ssh_config[:user], ssh_config) do |connection|
      bootstrap(connection, config)
    end
  end

  def self.bootstrap(connection, config)
    scp = Net::SCP.new connection
    puts connection.exec! "mkdir -p /etc/sod/cookbooks/sod/recipes"
    puts connection.exec! "chown -R #{config[:user]}:#{config[:user]} /etc/sod/cookbooks/sod/recipes"
    scp.upload! File.join(File.dirname(__FILE__), "rvm_install.sh"), "/etc/sod"
    scp.upload! File.join(File.dirname(__FILE__), "bootstrap.sh"), "/etc/sod"
    scp.upload! File.join(".", "/Sodfile"), "/etc/sod"
    puts connection.exec! "mkdir -p /etc/sod/cookbooks/sod/recipes"
    scp.upload! File.join(File.dirname(__FILE__), "default.rb"), "/etc/sod/cookbooks/sod/recipes"
    scp.upload! File.join(File.dirname(__FILE__), "bootstrap.rb"), "/etc/sod/cookbooks/sod/recipes"
    scp.upload! File.join(File.dirname(__FILE__), "project_chef.rb"), "/etc/sod/cookbooks/sod/recipes"
    scp.upload! File.join(".",config["key_location"]), "/etc/sod/id_sod" if config["key_location"]
    scp.upload! File.join(".",config["ssh_config_location"]), "/etc/sod" if config["ssh_config_location"]
    if config["remote_ssh_config_location"]
      puts connection.exec! "mkdir -p #{config["remote_ssh_config_location"]}"
      connection.exec! "mv /etc/sod/config #{config["remote_ssh_config_location"]}/config"
      connection.exec! "chown -R root:root #{config["remote_ssh_config_location"]}"
    end
    command =  "bash -cl 'RUBY=#{config["ruby_url"]} RUBY_HASH=#{config["ruby_hash"]} /etc/sod/bootstrap.sh'"
    puts command
    puts connection.exec! command
  end
end
=begin
  def self.install_ree_deps!(connection)
    puts "Installing REE deps..."
    puts connection.exec! "yum -y install gcc-c++ patch openssl-devel"
  end

  def self.install_build_essential!(connection)
    puts "Installing git and c"
    puts connection.exec! 'rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm'
    puts connection.exec! "yum -y install git gcc automake autoconf libtool make"
    puts connection.exec! "yum -y install readline readline-devel.x86_64 zlib zlib-devel.x86_64"
  end

  def self.upload_secret_files(connection)
    scp = Net::SCP.new connection
    dir = `echo ~/diaspora_cert`.strip + "/*"
    connection.exec! "mkdir -p /usr/local/nginx/conf"
    Dir.glob(dir).each {|file| scp.upload! file, "/usr/local/nginx/conf/"}
  end
=end
