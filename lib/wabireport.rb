# encoding: utf-8
#      Copyright (c) HongKong Stock Exchange and Clearing, Ltd.
#      All rights reserved.
#      Filename : report.rb
#      Project  : Wabi
#      Description: Cucumber json report parsing

require 'json'
require 'jsonpath'
# parse of cucumber json report with jsonpath
class Reporthandler
  def initialize(file_url)
    file = File.read(file_url)
    jreport = JSON.load(file)
    @features = []
    # feature is in first level in report.json
    feature_path = JsonPath.new("$.[?(@.keyword='Feature')]")
    feature_path.on(jreport).each do | feature |
      @features << Feature.new(feature)
    end
  end

  def feature
    @features.size
  end

  def passed_feature
    @features.select { |f| f.status == 'passed' }.size
  end

  def scenario
    num = 0
    @features.each do |f|
      num += f.scenarios.size
    end
    num
  end

  def passed_scenario
    num = 0
    @features.each do |f|
      f.scenarios.each do |s|
        num += 1 if s.status == 'passed'
      end
    end
    num
  end

  def duration
    duration = 0
    @features.each { |f| duration += f.duration }
    (duration.to_f / 1_000_000_000).round(2)
  end

  def scenario_average_duration
    num = 0
    duration = 0
    #    	binding.pry
    @features.each do |f|
      f.scenarios.each do |s|
        num += 1
        duration += s.duration
      end
    end
    res = duration / num
    (res.to_f / 1_000_000_000).round(2)
  end

  def scenario_shortest_duration
    shortest =  9_999_999_999_999_999_999_999_999
    @features.each do |f|
      f.scenarios.each do |s|
        shortest = s.duration if s.duration < shortest
      end
    end
    res = shortest
    (res.to_f / 1_000_000_000).round(2)
  end

  def scenario_longest_duration
    longest = 0
    @features.each do |f|
      f.scenarios.each do |s|
        longest = s.duration if s.duration > longest
      end
    end
    res = longest
    (res.to_f / 1_000_000_000).round(2)
  end
  # feature inside of the cucumber report
  class Feature
    attr_reader :duration
    attr_reader :status
    attr_reader :name
    attr_reader :scenarios

    def initialize(feature)
      # name
      res = JsonPath.new('$.name').on(feature)
      @name = res[0] if res.size == 1

      # scenario list
      @scenarios = []

      scenraio_path = JsonPath.new('$.elements') # [?(@.type)]

      res = scenraio_path.on(feature)
      res[0].each do | scenario |
        @scenarios << Scenario.new(scenario) if is_scenario? scenario
      end

      # duration
      @duration = 0
      @scenarios.each { |s| @duration += s.duration }
      # status
      @status = 'passed'
      @scenarios.each do |s|
        unless s.status == 'passed'
          @status = 'failed'
          break
        end
      end
    end

    def is_scenario?(scenario)
      res = JsonPath.new('$.type').on(scenario)
      return false unless res.size == 1
      if res[0] == 'scenario'
        return true
      else
        return false
      end
    end
  end
  # Scenario inside of the cucumber report
  class Scenario
    attr_reader :duration
    attr_reader :status
    attr_reader :name
    attr_reader :steps

    def initialize(scenario)
      # scenario only contains one steps list
      step_path = JsonPath.new('$.steps')
      @steps = []
      res = step_path.on(scenario)
      # fill in all steps
      res[0].each do | step |
        @steps << Step.new(step)
      end
      # duration
      @duration = 0
      @steps.each { |step|  @duration += step.duration }
      # status
      @status = 'passed'
      @steps.each do |s|
        unless s.status == 'passed'
          @status = 'failed'
          break
        end
      end
      # name
      res = JsonPath.new('$.name').on(scenario)
      @name = res[0] if res.size == 1
      #			binding.pry
    end
  end
  # Step inside of the cucumber report
  class Step
    attr_reader :duration
    attr_reader :status
    attr_reader :name

    def initialize(step_json)
      res = JsonPath.new('$.name').on(step_json)
      @name = res[0] if res.size == 1
      result = JsonPath.new('$.result').on(step_json)
      if result.size == 1
        res = JsonPath.new('$.status').on(result[0])
        @status = res[0] if res.size == 1
        res = JsonPath.new('$.duration').on(result[0])
        @duration = res[0] if res.size == 1
      end
    end
  end
end
