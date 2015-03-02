service "apache2" do
  case node[:platform]
  when "centos","redhat","fedora","suse"
    service_name "httpd"
    # If restarted/reloaded too quickly httpd has a habit of failing.
    # This may happen with multiple recipes notifying apache to restart - like
    # during the initial bootstrap.
    restart_command "/sbin/service httpd restart && sleep 1"
    reload_command "/sbin/service httpd reload && sleep 1"
  when "debian","ubuntu"
    service_name "apache2"
    restart_command "/usr/sbin/invoke-rc.d apache2 restart && sleep 1"
    reload_command "/usr/sbin/invoke-rc.d apache2 reload && sleep 1"
  end
  supports value_for_platform(
    "debian" => { "4.0" => [ :restart, :reload ], "default" => [ :restart, :reload, :status ] },
    "ubuntu" => { "default" => [ :restart, :reload, :status ] },
    "centos" => { "default" => [ :restart, :reload, :status ] },
    "redhat" => { "default" => [ :restart, :reload, :status ] },
    "fedora" => { "default" => [ :restart, :reload, :status ] },
    "default" => { "default" => [:restart, :reload ] }
  )
  action :enable
end

# Use pecl to install module
module_name = "mongo"

execute "install_php_#{module_name}_module" do
  command "pecl install #{module_name}"
  action :run
end


# Create template
template "#{module_name}.ini" do
  source "php_module.ini.erb"
  case node[:platform]
    when "centos","redhat","fedora","amazon"
      path "/etc/php.d/#{module_name}.ini"
    when "debian","ubuntu"

      if node[:platform_version].to_f >= 14.04
        path "/etc/php5/mods-available/#{module_name}.ini"
      else
        path "/etc/php5/conf.d/#{module_name}.ini"
      end

  end
  owner "root"
  group "root"
  mode "0644"
  variables(
    :name => "#{module_name}"
  )
  notifies :restart, resources(:service => "apache2")
end


# Place enable the module if required and restart apache
case node[:platform]
when "debian","ubuntu"
  execute "enable_#{module_name}" do
    user "root"
    command "php5enmod #{module_name}"
    only_if { ::File.exist?("/etc/php5/mods-available/#{module_name}.ini")}
    notifies :restart, resources(:service => "apache2")
  end
end
