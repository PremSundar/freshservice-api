#!/bin/bash 

if [ -e freshservice-0.1.gem ]; then 
  rm freshservice-0.1.gem
fi 

gem build freshservice.gemspec
sudo gem install freshservice-0.1.gem
