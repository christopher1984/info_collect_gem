# encoding: utf-8
#      Copyright (c) HongKong Stock Exchange and Clearing, Ltd.
#      All rights reserved.
#      Filename : utility.rb
#      Project  : Wabi
#      Description: utility functions used in Rakefile

require 'wabireport'
# A set of utility function used in Rakefile
class WabiUtility
  # remove all json report in workspace
  # initialize the result.csv
  def self.clean
    base = './'
    `rm -f #{base}*.json`
    # create initial result.csv
    unless File.exist? 'result.csv'
      File.open(base + 'result.csv', 'w') do |out_line|
        out_line.puts 'feature,passed_feature,scenario,passed_scenario,\
        total_duration,scenario_average,shortest_scenario,longest_scenario'
      end
    end
  end

  # change the feature name inside of the json report to include the testing environmnet
  def self.handle_report
    base = './'
    Dir.foreach(base) do | file |
      if file.to_s.end_with?('.json') and !file.to_s.start_with? 'handled'
        json = File.read(base + file)
        report = JSON.load(json)
        flist = Hash.new
        report.each do | feature |
          # parse browser, version, platform, language
          env = feature['elements'][0]['steps'][0]['output']
          if env.class == Array
            env = env[0].split(/,/)
            flist[feature['name']] = feature['name'] + '##Browser:' +
             env[0] + ',Version:' + env[1] + ',Platform:' + env[2] +
              ',Language:' + env[3]
            # STDOUT.puts feature['name'] + '####' + flist[feature['name']]
          end
        end
        File.open(base + "handled_#{file}", 'w') do |out_line|
          File.open(base + file, 'r').each do |in_line|
            changed = false
            flist.keys.each do |key|
              if in_line.include? key
                out_line.print in_line.sub(key, flist[key])
                changed = true
                break
              end
            end
            out_line.print in_line unless changed
          end
        end
        File.delete(file)
      end
    end
  end

  # accumulate the json report result to result.csv
  # MODIFICATION NEEDED! based on your statistics requirement
  def self.accumulate
    base = './'
    Dir.foreach(base) do | file |
      if file.to_s.end_with?('.json')
        rh = Reporthandler.new(base + file)
        File.open(base + 'result.csv', 'a') do |f|
          if File.exist? base + 'result.csv'
            f.puts rh.feature.to_s + ',' + rh.passed_feature.to_s +
             ',' + rh.scenario.to_s + ',' + rh.passed_scenario.to_s +
              ',' + rh.duration.to_s + ',' + rh.scenario_average_duration.to_s +
               ',' + rh.scenario_shortest_duration.to_s + ',' +
                rh.scenario_longest_duration.to_s
          end
        end
        break
      end
    end
  end
end
