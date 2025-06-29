# frozen_string_literal: true

module Clarity
  class ProjectsController
    def initialize
      @view = Clarity::ProjectsView.new
      @projects_repository = Clarity::ProjectRepository.new
    end

    def sync_with_github
      Clarity::GithubRepoImporter.call
    end

    def list_recent
      projects = @projects_repository.all
      projects.sort_by!(&:pushed_at).reverse!

      @view.display_list(projects.first(5))
    end

    def list(options)
      projects = @projects_repository.all

      projects = filter(projects, options[:filters]) if options[:filters]
      projects = sort(projects, options[:sort]) if options[:sort]
      projects.reverse! if options[:order]&.downcase == 'asc'
      projects = projects[0...options[:limit]] if options[:limit]

      @view.display_list(projects)
    end

    def show(name)
      unless name
        warn 'Error: Please enter the name of the project'
        exit 1
      end

      project = @projects_repository.find(name)
      unless project
        warn "Error: No project with name: #{name}"
        exit 1
      end

      @view.display_one(project)
    end

    def update(name)
      unless name
        warn 'Please enter the name of the project'
        exit 1
      end

      if name == 'all'
        projects = @projects_repository.all_with_no_metadata
        projects.each do |project|
          prompt_to_update(project)
          if project.status.nil? || project.urgency.nil? || project.type.nil?
            warn "Error! #{name} was not updated."
            exit 1
          end
          @projects_repository.save(project)
          puts 'Saved!'
        end

      else
        project = @projects_repository.find(name)

        unless project
          warn "Error: No project with name: #{name}"
          exit 1
        end

        prompt_to_update(project)
        if project.status.nil? || project.urgency.nil? || project.type.nil?
          warn "Error! #{name} was not updated."
          exit 1
        end
        @projects_repository.save(project)
        puts 'Saved!'
      end
    end

    def list_filters
      filters = Clarity::Project::FILTERS
      @view.display_filters(filters)
    end

    private

    def filter(projects, user_filters)
      projects.select do |project|
        user_filters.all? do |filter_by, filter_values|
          next true if filter_values.empty?

          matches_filter?(project, filter_by, filter_values)
        end
      end
    end

    def matches_filter?(project, filter_by, user_filters)
      project_value = project.send(filter_by)

      case project_value
      when Array
        user_filters_downcased = user_filters.map(&:downcase)
        shared_values = project_value & user_filters_downcased
        shared_values.any?
      when String
        # In case the user filters by multiple names
        user_filters.any? do |user_filter|
          # Check if the name contains the string the user filtered for
          project_value.to_s.downcase.include?(user_filter.downcase)
        end
      when Hash
        # This all and needs fixing
        # Languages is currently the only property of a Project that's a Hash
        # But if any other Hash properties get added, this will break
        # A better approach might be to get rid of this whole case statement and
        # write a to_filterable method to normalise project_value to a string
        user_filters_downcased = user_filters.map(&:downcase)

        project_languages = project_value
        languages_as_array = project_languages.keys.first(4).map(&:to_s).map(&:downcase)

        shared_values = languages_as_array & user_filters_downcased
        shared_values.any?
      end
    end

    def sort(projects, by)
      projects.sort_by! do |project|
        case by
        when 'name'       then project.name.downcase
        when 'status'     then Clarity::Project::STATUS_ORDER[project.status&.to_sym] || 999
        when 'urgency'    then Clarity::Project::URGENCY_ORDER[project.urgency&.to_sym] || 999
        when 'type'       then Clarity::Project::TYPE_ORDER[project.type&.to_sym] || 999
        when 'motivation' then Clarity::Project::MOTIVATION_ORDER[project.motivation&.to_sym] || 999
        when 'created_at' then Time.parse(project.created_at.to_s)
        when 'pushed_at'  then Time.parse(project.pushed_at.to_s)
        end
      end
    end

    def prompt_to_update(project)
      puts "Updating #{project.name}"
      project.status = nil
      project.urgency = nil
      project.type = nil

      until Clarity::Project::STATUSES.keys.include?(project.status&.to_sym)
        status = Clarity::CoreView.prompt('Status [deployed/development/archived/paused/idea/abandoned]:')
        project.status = status
      end

      until Clarity::Project::URGENCIES.keys.include?(project.urgency&.to_sym)
        urgency = Clarity::CoreView.prompt('Urgency [high/medium/low/none]:')
        project.urgency = urgency
      end

      until Clarity::Project::TYPES.keys.include?(project.type&.to_sym)
        type = Clarity::CoreView.prompt('Type [client/teaching/job/paused/learning/personal]:')
        project.type = type
      end

      until Clarity::Project::MOTIVATIONS.keys.include?(project.motivation&.to_sym)
        motivation = Clarity::CoreView.prompt('Motivation [hot/warm/cold/blocked/dread/finished]:')
        project.motivation = motivation
      end
    end
  end
end
