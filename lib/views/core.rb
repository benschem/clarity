# frozen_string_literal: true

module Clarity
  class CoreView
    def self.usage_help
      puts <<~USAGE
        Usage: clarity COMMAND [ARGS]

        Commands:
          sync               Fetch projects from Github
          list               List all projects
          list sort OPTION   OPTIONS: name, status, priority, type, motivation, created_at, pushed_at
          update ID          Update a project by it's ID
          new NAME           Create a new project
          finish NAME        Mark project as finished
          help               Prints this message
      USAGE
      exit 1
    end

    def self.prompt(question)
      print "#{question} "
      gets.chomp
    end
  end
end
