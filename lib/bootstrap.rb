Encoding.default_external = Encoding::UTF_8
config = YAML.load(File.read('/etc/sod/Sodfile'))["production"]
repo_name = config["repo"].split("/").last.gsub(".git","")
$APP_PATH = File.join(config["app_dir"],repo_name)

execute "set environment script" do
  command "echo 'export PATH=$PATH' > /etc/sod/environment"
end
execute "set environment in all shells" do
  command "echo 'source /etc/sod/environment' >> /etc/profile"
  not_if "grep /etc/sod/environment /etc/profile"
end

include_recipe (config["cookbook"] + "::bootstrap")

gem_package "bundler" do
  action :install
end

execute "Create app user" do
  command "(id app || useradd -d #{config["app_dir"]} app) && chown -R app ~app"
end

execute "Set up app user ssh" do
  command 'grep github.com ~app/.ssh/config || (mkdir -p ~app/.ssh && echo -e \'Host github.com\n\tStrictHostKeyChecking no\n\' >> ~app/.ssh/config)'
end

execute "Install the bundle" do
  command "cd #{$APP_PATH} && sudo -u app bundle install --deployment --without 'test development'"
end

