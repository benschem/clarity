# frozen_string_literal: true

module Clarity
  class ProjectsController
    def initialize
      @view = Clarity::ProjectsView.new
    end

    def sync_projects
      Clarity::GithubRepoImporter.call
    end

    def list_projects(options)
      projects = Clarity::ProjectRepository.new.all

      projects = filter(projects, options[:filters]) if options[:filters]
      projects = sort(projects, options[:sort]) if options[:sort]
      projects.reverse! if options[:order]&.downcase == 'asc'
      projects = projects[0...options[:limit]] if options[:limit]

      @view.display_list(projects)
    end

    def update_project
      project_repo = Clarity::ProjectRepository.new

      id = args.shift.to_i
      unless id
        # how to print help?
        return
      end

      project = project_repo.find(id)
      puts "Updating #{project.name}"

      until Clarity::Project::STATUSES.keys.include?(project.status.to_sym)
        status = Clarity::CoreView.prompt('Status [deployed/development/archived/paused/idea/abandoned]:')
        project.status = status
      end

      until Clarity::Project::URGENCIES.keys.include?(project.urgency.to_sym)
        urgency = Clarity::CoreView.prompt('Urgency [high/medium/low/none]:')
        project.urgency = urgency
      end

      until Clarity::Project::TYPES.keys.include?(project.type.to_sym)
        type = Clarity::CoreView.prompt('Type [paid/teaching/job/paused/learning/personal]:')
        project.type = type
      end

      until Clarity::Project::MOTIVATIONS.keys.include?(project.motivation.to_sym)
        motivation = Clarity::CoreView.prompt('Motivation [hot/warm/cold/blocked/dread/finished]:')
        project.motivation = motivation
      end

      project_repo.save(project)
      puts 'Saved!'
    end

    private

    def filter(projects, filters)
      projects.select do |project|
        filters.all? do |field, expected_values|
          next true if expected_values.empty?

          actual = project.send(field)

          if actual.is_a?(Array)
            (actual & expected_values).any?
          else
            expected_values.include?(actual.to_s)
          end
        end
      end
    end

    def sort(projects, by)
      projects.sort_by! do |project|
        case by
        when 'name'       then project.name.downcase
        when 'status'     then Clarity::Project::STATUS_ORDER[project.status.to_sym] || 999
        when 'urgency'    then Clarity::Project::URGENCY_ORDER[project.urgency.to_sym] || 999
        when 'type'       then Clarity::Project::TYPE_ORDER[project.type.to_sym] || 999
        when 'motivation' then Clarity::Project::MOTIVATION_ORDER[project.motivation.to_sym] || 999
        when 'created_at' then Time.parse(project.created_at.to_s)
        when 'pushed_at'  then Time.parse(project.pushed_at.to_s)
        end
      end
    end
  end
end
