# frozen_string_literal: true

require 'terminal-table'

module Clarity
  class ProjectsView
    MAX_DESCRIPTION_LENGTH = 60

    def display_one(project)
      rows = [
        [project.id, project.status, project.name],
        [project.description]
      ]
      table = Terminal::Table.new do |t|
        # t.headings = %w[id stts urgc name type description mtvn]
        t.rows = rows
        t.style = { all_separators: true }
        # t.align_column(1, :center)
        # t.align_column(2, :center)
        # t.align_column(4, :center)
        # t.align_column(6, :center)
      end

      puts table
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
