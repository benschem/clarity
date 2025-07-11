# frozen_string_literal: true

require 'terminal-table'

module Clarity
  class ProjectsView
    def display_one(project)
      puts '----'
      puts project.name
      puts '----'
      project.languages.each do |language, lines|
        print "#{language} (#{(lines.to_i / project.total_lines.to_i) * 100}%), "
      end
      puts ''
      puts '----'
      puts "#{'Created:'.ljust(12)} #{project.created_days_ago} days ago"
      puts "#{'Last pushed:'.ljust(12)} #{project.pushed_days_ago} days ago"
      puts '----'
      puts "[#{create_status(project)}] Status: #{project.status}"
      puts "[#{create_urgency(project)}] Urgency: #{project.urgency}"
      puts "[#{create_type(project)}] Type: #{project.type}"
      puts "[#{create_motivation(project)}] Motivation: #{project.motivation}"
      puts '----'
      puts project.description

      project_dir = File.expand_path("~/code/benschem/#{project.name}")
      todo_file = File.join(project_dir, 'todo.md')

      if File.exist?(todo_file)
        puts "\n----"
        puts "Todo List (#{todo_file}):"
        puts '----'
        puts File.read(todo_file)
      else
        puts "\n(No `todo.md` file found in #{project_dir})"
      end
      # rows = [
      #   ["#{create_status(project)} #{project.status}", "#{create_urgency(project)} #{project.urgency}",
      #    project.name.to_s, "#{create_type(project)} #{project.type}", "#{create_motivation(project)} #{project.motivation}"]
      # ]
      # table = Terminal::Table.new do |t|
      #   t.headings = %w[status urgcency name type motivation]
      #   t.rows = rows
      #   t.style = { all_separators: true }
      #   t.align_column(1, :center)
      #   t.align_column(2, :center)
      #   t.align_column(4, :center)
      #   t.align_column(6, :center)
      # end
      # puts table

      # table = Terminal::Table.new do |t|
      #   t.rows =  [[project.description]]
      #   t.style = { all_separators: true }
      # end

      # puts table
    end

    def display_list(projects)
      if projects.empty?
        puts 'No projects found.'
        return
      end

      rows = create_rows(projects)

      table = Terminal::Table.new do |t|
        t.headings = %w[stts urgc name type mtvn created pushed]
        t.rows = rows
        t.style = { all_separators: true }
        t.align_column(0, :center)
        t.align_column(1, :center)
        t.align_column(3, :center)
        t.align_column(4, :center)
      end

      puts table
    end

    def display_filters(filters)
      puts 'Filter usage:'
      puts '> clarity list --filter KEY=VALUE'
      puts ''
      puts "#{'KEYS'.ljust(13)}VALUES"
      filters.each do |field, values|
        label = field.to_s.ljust(12)
        value =
          if values == :text
            field.to_s == 'languages' ? 'type any language name (exact matching)' : 'type any text (partial matching)'
          else
            values.join(', ')
          end
        puts "#{label} #{value}"
      end
      puts ''
      puts 'Filters can be repeated:'
      puts '> clarity list --filter urgency=high --filter type=client'
    end

    private

    def create_rows(projects)
      projects.map do |project|
        name = project.name
        status = create_status(project)
        urgency = create_urgency(project)
        type = create_type(project)
        motivation = create_motivation(project)
        created = "#{project.created_days_ago} days ago"
        pushed = "#{project.pushed_days_ago} days ago"

        [status, urgency, name, type, motivation, created, pushed]
      end
    end

    def create_status(project)
      project.status ? Clarity::Project::STATUSES[project.status.to_sym] : ''
    end

    def create_urgency(project)
      project.urgency ? Clarity::Project::URGENCIES[project.urgency.to_sym] : ''
    end

    def create_type(project)
      project.type ? Clarity::Project::TYPES[project.type.to_sym] : ''
    end

    def create_motivation(project)
      project.motivation ? Clarity::Project::MOTIVATIONS[project.motivation.to_sym] : ''
    end
  end
end
