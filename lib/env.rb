# encoding: utf-8
#     Copyright (c) HongKong Stock Exchange and Clearing, Ltd.
#     All rights reserved.
#     Filename : env.rb
#     Project  : Wabi
#     Description: cucumber env file

require 'selenium-webdriver'
require 'csv'
require 'mini_magick'

# env.rb will be executed before any scenario
Before do
  @lang = ENV['LANGUAGE'] || 'en'
  # bigmap store the user defined variables
  @bigmap = Hash.new
  @RETRY_NUM = 3
end

# will be executed after any scenario
After do |s|
  if ENV['SCREENSHOT'] == 'on' and @driver
    @driver.save_screenshot("screenshots/#{s.__id__}.png")
    if s.failed?
      puts "#{s.title} is failed, screenshot: screenshots/#{s.__id__}.png "
    else
      puts "#{s.title} is sccessed, screenshot: screenshots/#{s.__id__}.png "
    end
  end

  @driver.quit if @driver
  @bigmap = nil
end
