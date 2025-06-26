# frozen_string_literal: true

require 'config/environment'

module Clarity
  class CLI
    PROGRAM_NAME = 'clarity'
    VERSION = '0.2.0'

    attr_reader :option_parser

    def initialize
      @parser = Clarity::OptionsParser.new
      @parser.parse!
      @options = @parser.options
      @projects_controller = Clarity::ProjectsController.new
    end

    def self.run(argv)
      new.run(argv)
    end

    def run(argv)
      command = argv.shift

      case command
      when 'sync'
        @projects_controller.sync_with_github
      when 'list'
        @projects_controller.list(@options)
      when 'recent'
        @projects_controller.list_recent
      when 'show'
        name = argv.shift
        @projects_controller.show(name)
      when 'update'
        name = argv.shift
        @projects_controller.update(name)
      when 'filters'
        @projects_controller.list_filters
      when 'help'
        puts @parser.parser
      else
        warn "Unrecognised command: #{command}"
        puts @parser.parser
      end
    end
  end
end
