# encoding: utf-8
#      Copyright (c) HongKong Stock Exchange and Clearing, Ltd.
#      All rights reserved.
#      Filename : wabitask.rb
#      Project  : Wabi
#      Description: override Cucumber task for integration with Jenkins

require 'cucumber'
require 'cucumber/rake/task'

#override Cucumber task for integration with Jenkins
class Wabitask < Cucumber::Rake::Task
  class WabiInProcessCucumberRunner #:nodoc:
    include ::Rake::DSL if defined?(::Rake::DSL)
    attr_reader :args
    def initialize(libs, cucumber_opts, feature_files)
      fail 'libs must be an Array when running in-process' unless Array === libs
      libs.reverse.each { |lib| $LOAD_PATH.unshift(lib) }
      @args = (
      cucumber_opts +
      feature_files
      ).flatten.compact
    end

    def run
      require 'cucumber/cli/main'
      failure = Cucumber::Cli::Main.execute(args)
      # raise "Cucumber failed" if failure
    end
   end

  class WabiForkedCucumberRunner #:nodoc:
    include ::Rake::DSL if defined?(::Rake::DSL)
    def initialize(libs, cucumber_bin, cucumber_opts, bundler, feature_files)
      @libs = libs
      @cucumber_bin = cucumber_bin
      @cucumber_opts = cucumber_opts
      @bundler = bundler
      @feature_files = feature_files
    end

    def load_path(_libs)
      ['"%s"' % @libs.join(File::PATH_SEPARATOR)]
    end

    def quoted_binary(cucumber_bin)
      ['"%s"' % cucumber_bin]
    end

    def use_bundler
      @bundler.nil? ? File.exist?('./Gemfile') && bundler_gem_available? : @bundler
    end

    def bundler_gem_available?
      Gem::Specification.find_by_name('bundler')
      rescue Gem::LoadError
      false
    end

    def cmd
      if use_bundler
        [Cucumber::RUBY_BINARY, '-S', 'bundle', 'exec', 'cucumber', @cucumber_opts,
         @feature_files].flatten
      else
        [Cucumber::RUBY_BINARY, '-I', load_path(@libs), quoted_binary(@cucumber_bin),
         @cucumber_opts, @feature_files].flatten
      end
    end

    def run
      sh cmd.join(' ') do |_ok, _res|
        # if !ok
        # exit res.exitstatus
        # end
      end
    end
 end

  def runner(_task_args = nil) #:nodoc:
    cucumber_opts = [(ENV['CUCUMBER_OPTS'] ? ENV['CUCUMBER_OPTS'].split(/\s+/) : nil) || cucumber_opts_with_profile]
    if @fork
      return WabiForkedCucumberRunner.new(libs, binary, cucumber_opts, bundler, feature_files)
    end
    WabiInProcessCucumberRunner.new(libs, cucumber_opts, feature_files)
 end
end
