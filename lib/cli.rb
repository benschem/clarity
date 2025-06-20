# frozen_string_literal: true

require 'config/environment'

module Clarity
  class CLI
    PROGRAM_NAME = 'clarity'
    VERSION = '0.0.1'

    attr_reader :option_parser

    def initialize
      @parser = Clarity::OptionsParser.new
      @parser.parse!
      @options = @parser.options
      @controller = Clarity::ProjectsController.new
    end

    def self.run(argv)
      new.run(argv)
    end

    def run(argv)
      command = argv.shift

      case command
      when 'sync'
        @controller.sync_projects
      when 'list'
        @controller.list_projects(@options)
      when 'show'
        name = argv.shift
        @controller.show_project(name)
      when 'update'
        name = argv.shift
        @controller.update_project(name)
      when 'filters'
        @controller.list_filters
      when 'help'
        puts @parser
      else
        warn "Unrecognised command: #{command}"
        puts @parser
      end
    end
  end
end
