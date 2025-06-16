# frozen_string_literal: true

require 'bundler/setup'

require 'models/github_repo_importer'
require 'models/project'
require 'repositories/project_repository'
require 'views/core'
require 'views/projects'

command = ARGV.shift

case command
when 'sync'
  Clarity::GithubRepoImporter.call
when 'list'
  project_repo = Clarity::ProjectRepository.new
  projects = project_repo.all

  option = ARGV.shift
  unless option
    Clarity::ProjectsView.list(projects)
    return
  end

  case option
  when 'sort'
    sort_param = ARGV.shift
    unless sort_param
      Clarity::CoreView.usage_help
      return
    end
    projects_sorted = project_repo.sort_projects(projects, sort_param)
    Clarity::ProjectsView.list(projects_sorted)
  end
when 'update'
  project_repo = Clarity::ProjectRepository.new
  projects = project_repo.all

  id = ARGV.shift.to_i
  unless id
    Clarity::CoreView.usage_help
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

# when 'new'
#   name = ARGV.shift
#   Clarity::CoreView unless name

#   Clarity::ProjectRepository.new(name)
# when 'finish'
#   name = ARGV.shift
#   Clarity::CoreView unless name

#   Clarity::ProjectRepository.finish(name)
when 'help'
  Clarity::CoreView.usage_help
else
  puts "Unrecognised command: #{command}"
  Clarity::CoreView.usage_help
end
