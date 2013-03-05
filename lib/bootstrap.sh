#! /bin/bash
set -ex
# RVM dependencies
apt-get install build-essential bison openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libxml2-dev libxslt-dev autoconf libc6-dev libyaml-dev -y
#rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm || true
#/usr/bin/yum install gcc gcc-c++ kernel-devel patch make bison openssl libreadline6 libreadline6-devel curl git-core zlib1g zlib1g-devel libssl-devel libxml2-devel libxslt-devel autoconf libc6-devel -y


cd /etc/sod

if ! ls /usr/local/bin/ruby; then
  curl -o ruby.tar.gz $RUBY
  if ! md5sum ruby.tar.gz | grep $RUBY_HASH; then
    exit 1;
  fi;
  tar -xf /etc/sod/ruby.tar.gz
  cd ruby*
  ./configure
  make
  make install
fi;

# REALLY_GEM_UPDATE_SYSTEM=true gem1.9.1 update --system

gem install chef --no-rdoc --no-ri
echo 'cookbook_path "/etc/sod/cookbooks"' > /etc/sod/solo.rb

grep github.com ~/.ssh/config || (
  echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config &&
  echo -e "\tIdentityFile /etc/sod/id_sod" >> ~/.ssh/config
)

# export PATH=$PATH:/var/lib/gems/1.9.1/bin/

echo '{"recipes": ["sod::default"]}' > /etc/sod/cookbooks/sod/sod.json
chef-solo -c /etc/sod/solo.rb -j /etc/sod/cookbooks/sod/sod.json

echo '{"recipes": ["sod::project_chef"]}' > /etc/sod/cookbooks/sod/project_chef.json
chef-solo -c /etc/sod/solo.rb -j /etc/sod/cookbooks/sod/project_chef.json
