#      Copyright (c) HongKong Stock Exchange and Clearing, Ltd.
#      All rights reserved.
#      Filename : basis.rb
#      Project  : Wabi
#      Description: wabi system defined cucumber stpes

################## SYSTEM OPERATIONS
# input testing environment information,
# this info will be used in handle_report Rake task
Given(/^Input testing environment$/) do
  puts "#{ENV['BROWSER']},#{ENV['VERSION']},#{ENV['PLATFORM']},#{ENV['LANGUAGE']}"
end

Given(/^Load object from (\w+)$/) do | project |
  csv = CSV.read("resource/#{project}.csv", encoding: 'bom|utf-8')
  obj = csv.map { |arr| [arr[0], arr[1]]  }
  acc = csv.map { |arr| [arr[0], arr[2]]  }
  @object_hash = Hash[obj]
  @object_acc = Hash[acc]
  # language overriding
  if File.exist?("resource/#{project}_#{@lang}.csv")
    csv = CSV.read("resource/#{project}_#{@lang}.csv", encoding: 'bom|utf-8')
    csv.each { |arr| @object_hash[arr[0]] = arr[1]  }
  end
end

Given(/^Load value from (\w+)$/) do | project |
  csv = CSV.read("resource/#{project}.csv", encoding: 'bom|utf-8')
  @value_hash = Hash[csv]
  # language overriding
  if File.exist?("resource/#{project}_#{@lang}.csv")
    csv = CSV.read("resource/#{project}_#{@lang}.csv", encoding: 'bom|utf-8')
    csv.each { |arr| @value_hash[arr[0]] = arr[1]  }
  end
end

# #############BASIC OPERATIONS
Given(/^I open the browser$/) do
  # driver is defined by the ENV BROSER VERSION PLATFORM MODE
  if not ENV['BROWSER'] || ENV['VERSION'] || ENV['PLATFORM'] || ENV['MODE']
    raise "Env BROWSER | VERSION | PLATFORM | MODE is not all provided!!!"
  end
  @driver = Browser.get_driver ENV['BROWSER'], ENV['VERSION'], ENV['PLATFORM'], ENV['MODE']
  raise "browser is not successfully loaded" if not @driver
  @driver.manage.window.maximize;
end

Given(/^I open the page with (\w+)$/) do | link |
  url = @value_hash[link]
  @driver.get url
  sleep 10
end

Given(/^I goback the page$/) do
  @driver.navigate.back
end

Given(/^I click the (\w+)$/) do | obj |
  try_num =0
  while try_num < @RETRY_NUM
    begin
      element = Browser.find_element(@object_hash, @object_acc, obj)
      Browser.highlight(element, 3) if ENV['HIGHLIGHT'] == 'on'
      element.click
      break
    rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
      try_num +=1
    end
  end
end

Given(/^I submit the (\w+)$/) do | obj |
  element = Browser.find_element(@object_hash, @object_acc, obj)
  Browser.highlight(element, 3) if ENV['HIGHLIGHT'] == 'on'
  element.submit
end


# the first obj is the select box, the second one as the selected object
Given(/^I select the (\w+) with (\w+)$/) do | obj, var|
  Browser.select_element(@object_hash, @object_acc, obj, @value_hash[var])
end

Given(/^I input the (\w+) with (\w+)$/) do |obj, value|
  if @object_acc[obj] == 'javascript'
    @driver.execute_script("#{@object_hash[obj]}.setAttribute('value', '#{@value_hash[value]}')")
  else
    element = Browser.find_element(@object_hash, @object_acc, obj)
    element.clear
    Browser.highlight(element, 3) if ENV['HIGHLIGHT'] == 'on'
    element.send_keys @value_hash[value]
  end
end

Given(/^I save the (\w+) with (\w+)$/) do |obj, variable|
  element = Browser.find_element(@object_hash, @object_acc, obj)
  @bigmap[variable] = element
end

Given(/^I download the (\w+) with (\w+)$/) do |_filename, link|
  url = @value_hash[link]
  @driver.get url
end

Given(/^I verify the page with (\w+)$/) do | context |
  @driver.find_element(xpath: "//*[contains(text(), '#{context}')]")
end

Given(/^I verify the alert with (\w+)$/) do | text |
  alert = @driver.switch_to.alert
  fail "alert doesn't include #{@value_hash[text]}" unless alert.text.include? @value_hash[text]
  alert.accept
end

Given(/^I hover_on the (\w+)$/) do | obj |
  element = Browser.find_element(@object_hash, @object_acc, obj)
  @driver.mouse.move_to(element)
end

Given(/^I type the (\w+)$/) do | key |
  # element = Browser.find_element(@object_hash, @object_acc, obj)
  @driver.keyboard.send_keys(key)
end

Given(/^I verify the title with (\w+)$/) do | var |
  if not @driver.title.include? @value_hash[var]
    raise "Browser title is not #{@value_hash[var]} !!! " 
  end
end

Given(/^I goto the popup$/) do 
  sleep 3
  @main_window = @driver.window_handle
  windows = @driver.window_handles
  windows.each do |window|
    if @main_window != window
      @new_window = window
    end
  end

  @driver.switch_to.window(@new_window) if not @new_window == nil#(@driver.window_handles.last)
end

Given(/^I close the popup$/) do 
  @driver.close
  @driver.switch_to.window(@main_window)#(@driver.window_handles.last)
  @new_window=nil
end

Given(/^screenshot named (\w+) in (\w+)$/) do | name , folder |
  image_format="png"
  basedir="screenshots/#{folder}"
  base_tmp_image="#{basedir}/tmp_base.#{image_format}"
  Dir.mkdir(basedir) if not File.exist? (basedir)
  
  entire_page_captured = false

  if ENV['BROWSER'] != 'chrome'
     entire_page_captured = true
  else
    inner_height = @driver.execute_script("return window.innerHeight;")
    inner_width = @driver.execute_script("return window.innerWidth;")
    document_height = @driver.execute_script("return Math.max(document.documentElement[\"clientHeight\"], document.body[\"scrollHeight\"], document.documentElement[\"scrollHeight\"], document.body[\"offsetHeight\"], document.documentElement[\"offsetHeight\"]);;")
    
    page_down_num = document_height / inner_height 
    entire_page_captured = true if page_down_num == 0
  end

  if entire_page_captured
    @driver.save_screenshot("#{basedir}/#{name}.#{image_format}")
  else
    createnewimage= "`convert -size #{inner_width}x#{document_height} xc:white #{base_tmp_image}`"
    eval createnewimage
    base_image = MiniMagick::Image.new("#{base_tmp_image}")
    for page_num in 0..page_down_num
      @driver.execute_script("scrollTo(0,#{page_num*inner_height})")
      # save the image of the each page
      image_url="#{basedir}/#{name}-part#{page_num}.#{image_format}"
      @driver.save_screenshot image_url
      tmp_image = MiniMagick::Image.new image_url
      # composite the page to the base image
      base_image = base_image.composite(tmp_image) do |c|
        c.compose "Over"
        c.geometry "+0+#{page_num*inner_height}"  if page_num != page_down_num
        c.geometry "+0+#{document_height-inner_height}"  if page_num == page_down_num
      end
      File.delete image_url
    end 

    base_image.write "#{basedir}/#{name}.#{image_format}"
    File.delete base_tmp_image
  end
end

Given(/^screenshot named (\w+) in (\w+) with (\w+)$/) do | name , folder , option|
  date_info_format="%y%m%d%H%M"
  if option == "env"
    name += "_"+ENV['BROWSER']+ENV['VERSION']+ENV['PLATFORM']
  end
  if option == "date"
    time = Time.new
    name += "_"+ time.strftime(date_info_format)
  end
  if option == "all"
    time = Time.new
    name += "_"+ENV['BROWSER']+ENV['VERSION']+ENV['PLATFORM']+"_"+ time.strftime(date_info_format)
  end
  steps %{
    * screenshot named #{name} in #{folder}
  }
end


##########################################################

Given(/^I verify the page with:$/) do | tab |
  tab.hashes.each do |row |
  
# xpath      @driver.find_element(xpath: "//*[contains(text(), '#{row[@lang]}')]")
    element = @driver.find_element(css: 'body')
    if element
      if not element.text.include? row[@lang]
        res = @driver.find_element(xpath: "//*[contains(text(), '#{row[@lang]}')]")
        raise "Can not find #{row[@lang]}!!!" if res == nil 
      end 
    
     end
   end
end

Given(/^I search the (\w+) with:$/) do | obj, tab |
  tab.hashes.each do |row |
    # check firstly with css locator in a scope
    element = Browser.find_element(@object_hash, @object_acc, obj)
    if element
      unless element.text.include? row[@lang]
        res = @driver.find_element(xpath:
          "//*[contains(text(), '#{row[@lang]}')]")
        fail "Can not find #{row[@lang]}!!!" if res.nil?
      end 
    end 
  end 
end

