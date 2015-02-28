# encoding: utf-8
#      Copyright (c) HongKong Stock Exchange and Clearing, Ltd.
#      All rights reserved.
#      Filename : browser.rb
#      Project  : Wabi
#      Description: class browser file

# Class browser is the object encapsulating the Selenium web driver operations
class Browser
  # browserName chrome|firefox|internet explorer|opera|safari
  # version The browser version, or 0 if unknown.
  # platform WINDOWS|XP|VISTA|MAC|LINUX|UNIX|ANDROID
  def self.get_driver(type, version, platform, mode)
    version = version.to_i
    version =  '''' if version == 0
    platform ||=  'ANY'
    mode ||= 'remote'
    # specify remote capabilities
    caps = Browser.caps(type, version, platform)
    Browser.driver(mode, caps, type)
  end

  def self.find_element(objhash, acchash, obj)
    object = objhash[obj]
    acc = acchash[obj]
    element = case acc
              when 'id'  then @driver.find_element(id: object)
              when 'link' then  @driver.find_element(link: object)
              when 'xpath' then  @driver.find_element(xpath: object)
              when 'css' then @driver.find_element(css: object)
              when 'name' then @driver.find_element(:name, object)
    end
    element
  end

  def self.select_element(objhash, acchash, obj, value)
    element = Browser.find_element(objhash, acchash, obj)
    eval("Selenium::WebDriver::Support::Select.new(element).select_by(:text, '#{value}')")
  end

  def self.highlight(element, duration = 3)
    # store original style so it can be reset later
    original_style = element.attribute('style')

    # style element with red border
    @driver.execute_script(
      'arguments[0].setAttribute(arguments[1], arguments[2])',
      element,
      'style',
      'border: 5px solid red; border-style: dashed;')

    # keep element highlighted for a spell and then revert
    if duration > 0
      sleep duration
      @driver.execute_script(
       'arguments[0].setAttribute(arguments[1], arguments[2])',
       element,
       'style',
       original_style)
    end
  end

  # get the web browser handle
  def self.driver(mode, caps, type)
    if mode.to_sym  == :remote
      @driver = Selenium::WebDriver.for :remote, desired_capabilities: caps
    else
      @driver = Selenium::WebDriver.for type.to_sym
    end
    # default timeout 20 seconds
    @driver.manage.timeouts.implicit_wait = 20
    @driver
  end

  # get capabilities strings
  def self.caps(type, version, platform)
    # specify remote capabilities
    if type.to_sym == :chrome || type.to_sym == :firefox
      caps = { browserName: type.to_sym,
        version: version, platform: "#{platform}",
        javascriptEnabled: true, cssSelectorsEnabled: true,
        takesScreenshot: true, nativeEvents: true }
    elsif type.to_sym  == :ie
      caps = { browser_name: type.to_sym,
        version: version, platform: "#{platform}",
        javascript_enabled: true, css_selectors_enabled: true,
        takes_screenshot: true, native_events: true }
    end
    caps
  end
end
