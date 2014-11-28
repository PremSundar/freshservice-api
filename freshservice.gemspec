# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'freshservice'
  s.version     = "0.0.1"
  s.date        = '2014-11-28'
  s.summary     = "Ruby Gem for interfacing with the Freshservice API"
  s.description = "Ruby Gem for interfacing with the Freshservice API"
  s.authors     = ["David Liman", "Tim Macdonald"]
  s.files       = ["lib/freshservice.rb"]
  s.homepage    = 'https://github.com/PremSundar/freshservice-api'
  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'nokogiri'
end
