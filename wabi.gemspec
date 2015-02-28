
Gem::Specification.new do |s|
  s.name        = 'wabi'
  s.version     = '2.0'
  s.date        = '2015-02-11'
  s.summary     = 'Wabi Test Framework'
  s.description = "A web browser testing Framework"
  s.authors     = ["HKEX"]
  s.email       = ''
  s.homepage    = ''
  s.license       = ''


  s.add_runtime_dependency 'auto_click', '~>0.2'
  s.add_runtime_dependency 'cucumber', '~> 1.3'
  s.add_runtime_dependency 'selenium-webdriver','~> 2.43'
  s.add_runtime_dependency 'json','~> 1.5'
  s.add_runtime_dependency 'jsonpath','~> 0.5'
  s.add_runtime_dependency 'mini_magick', '~> 4.0.2'

  s.require_path = "lib"
  s.files = ["lib/wabi.rb","lib/env.rb", "lib/basis.rb","lib/browser.rb","lib/wabitask.rb","lib/wabireport.rb","lib/wabiutility.rb"]
end