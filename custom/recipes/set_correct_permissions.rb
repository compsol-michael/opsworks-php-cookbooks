C#
# Taken from:
# http://docs.aws.amazon.com/opsworks/latest/userguide/gettingstarted.walkthrough.photoapp.3.html
#
node[:deploy].each do |application, deploy|
  script "set_correct_permissions" do
    interpreter "bash"
    user "root"
    cwd "#{deploy[:deploy_to]}"
    code <<-EOH
    chmod -R 777 current
    EOH
  end
end 
