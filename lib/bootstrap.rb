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

execute "Install the bundle" do
  command "useradd -d #{$APP_PATH} app && chown -R app #{$APP_PATH}"
end

execute "Install the bundle" do
  command "cd #{$APP_PATH} && sudo -u app bundle install --deployment --without 'test development'"
end

