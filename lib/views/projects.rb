# frozen_string_literal: true

require 'terminal-table'

module Clarity
  class ProjectsView
    MAX_DESCRIPTION_LENGTH = 60

    def display_one(project)
      puts "[#{project.id}]"
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
      # rows = [
      #   [project.id.to_s, "#{create_status(project)} #{project.status}", "#{create_urgency(project)} #{project.urgency}",
      #    project.name.to_s, "#{create_type(project)} #{project.type}", "#{create_motivation(project)} #{project.motivation}"]
      # ]
      # table = Terminal::Table.new do |t|
      #   t.headings = %w[id status urgcency name type motivation]
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
        t.headings = %w[id stts urgc name type description mtvn]
        t.rows = rows
        t.style = { all_separators: true }
        t.align_column(1, :center)
        t.align_column(2, :center)
        t.align_column(4, :center)
        t.align_column(6, :center)
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
        id = project.id
        name = project.name
        description = create_description(project)
        status = create_status(project)
        urgency = create_urgency(project)
        type = create_type(project)
        motivation = create_motivation(project)

        [id, status, urgency, name, type, description, motivation]
      end
    end

    def create_description(project)
      "#{project.description[0..60]}..." if project.description&.length&.> MAX_DESCRIPTION_LENGTH
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
