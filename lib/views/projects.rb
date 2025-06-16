# frozen_string_literal: true

require 'terminal-table'

module Clarity
  class ProjectsView
    MAX_DESCRIPTION_LENGTH = 60

    def self.list(projects)
      if projects.empty?
        puts 'No projects found.'
        return
      end

      rows = projects.map do |project|
        id = project.id
        name = project.name
        description = project.description
        description = "#{description[0..60]}..." if description&.length&.> MAX_DESCRIPTION_LENGTH
        status = project.status ? Clarity::Project::STATUSES[project.status.to_sym] : ''
        urgency = project.urgency ? Clarity::Project::URGENCIES[project.urgency.to_sym] : ''
        type = project.type ? Clarity::Project::TYPES[project.type.to_sym] : ''
        motivation = project.motivation ? Clarity::Project::MOTIVATIONS[project.motivation.to_sym] : ''

        [id, status, urgency, name, type, description, motivation]
      end

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
  end
end
