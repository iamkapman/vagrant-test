# Non-free Repo
apt_repository 'debian-non-free' do
  uri          'http://http.us.debian.org/debian'
  distribution 'jessie'
  components   ['non-free']
  deb_src      true
end

# MySQL server
package 'mysql-server'

file '/etc/mysql/conf.d/custom.cnf' do
  content '[mysqld]
  key_buffer_size = 256M
  table_cache = 1024
  thread_cache_size = 16
  query_cache_size = 32M
  '
  mode '0644'
  owner 'mysql'
  group 'mysql'
  backup false
end

# Install Apache
include_recipe "apache2"
include_recipe "apache2::mpm_prefork"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_actions"
include_recipe "apache2::mod_alias"
include_recipe "apache2::mod_auth_basic"
include_recipe "apache2::mod_deflate"
include_recipe "apache2::mod_include"
include_recipe "apache2::mod_php5"

# Install PHP
package 'php5-mysql'
package 'php5-common'
package 'php5-curl'
package 'php5-xdebug'

# Config Apache + PHP
conf_plain_file '/etc/php5/apache2/php.ini' do
  current_line 'short_open_tag = Off'
  new_line 'short_open_tag = On'
  action :replace
end

conf_plain_file '/etc/php5/mods-available/xdebug.ini' do
  pattern /remote_enable/
  new_line "xdebug.remote_enable = on\nxdebug.remote_connect_back = on\nxdebug.idekey = \"vagrant\"\nxdebug.profiler_enable = 1\nxdebug.profiler_enable_trigger = 1\nxdebug.profiler_output_dir = \"/var/www/logs/xdebug/\""
  action :insert_if_no_match
end

conf_plain_file '/etc/apache2/sites-enabled/000-default.conf' do
  current_line 'AllowOverride None'
  new_line 'AllowOverride All'
  action :replace
end

# Restart services
service "apache2" do
  action :restart
end

service "mysql" do
  action :restart
end

# Download MySQL dump
execute 'dumpextract' do
  command 'tar xfz /var/www/install/dump.tgz -C /var/www/install/ --overwrite'
  action :nothing
end

remote_file '/var/www/install/dump.tgz' do
  source node['custom']['dump_url']
  owner 'www-data'
  group 'www-data'
  mode '0644'
  headers({"Authorization" => "Basic #{Base64.encode64("#{node['custom']['login']}:#{node['custom']['password']}").gsub("\n", "") }" }) 
  action :create_if_missing
  notifies :run, 'execute[dumpextract]', :immediate
end

# Extract MySQL dump
Dir[ "/var/www/install/**/*.sql" ].each do |curr_path|
  execute curr_path do
    command "/usr/bin/mysql -uroot -h127.0.0.1 --password= -e 'CREATE DATABASE IF NOT EXISTS #{File.dirname(curr_path).split('/').last}'"
  end
  execute curr_path do
    command "/usr/bin/mysql -uroot -h127.0.0.1 --password= #{File.dirname(curr_path).split('/').last} < #{curr_path}"
  end
  file curr_path do
    action :delete
  end if File.file?(curr_path)
end

# Download configs
execute 'configextract' do
  command 'tar xfz /var/www/install/configs.tgz -C /var/www/ --overwrite'
  action :nothing
end

remote_file '/var/www/install/configs.tgz' do
  source node['custom']['conf_url']
  owner 'www-data'
  group 'www-data'
  mode '0644'
  headers({"Authorization" => "Basic #{Base64.encode64("#{node['custom']['login']}:#{node['custom']['password']}").gsub("\n", "") }" }) 
  action :create_if_missing
  notifies :run, 'execute[configextract]', :immediate
end

conf_plain_file '/var/www/conf_site.php' do
  pattern /By vagrant/
  new_line '$INFO[\'sql_user\'] = "root"; $INFO[\'sql_pass\'] = ""; // By vagrant'
  action :insert_if_no_match
end
