# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'date'

module Clarity
  attr_reader :all, :sort_projects

  class ProjectRepository
    PROJECTS_DIR = File.expand_path('~/.clarity/projects')
    METADATA_DIR = File.expand_path('~/.clarity/metadata')

    def initialize
      @projects = load_all_projects
    end

    def all
      @projects
    end

    def find(id)
      @projects.find { |project| project.id == id }
    end

    def save(project)
      metadata = {
        status: project.status,
        urgency: project.urgency,
        type: project.type,
        motivation: project.motivation
      }
      metadata_path = File.join(METADATA_DIR, "#{project.name}.json")
      begin
        FileUtils.mkdir_p(File.dirname(metadata_path))
        File.write(metadata_path, JSON.pretty_generate(metadata))
      rescue SystemCallError, IOError => e
        warn "Error: Failed to write metadata: #{e.message}"
      end
    end

    # def new(name)
    #   if load(name)
    #     warn "Project '#{name}' already exists."
    #     exit 1
    #   end

    #   summary = Clarity::App.prompt("Summary:")
    #   effort = Clarity::App.prompt("Estimated effort (e.g. 1hr, weekend):")
    #   excitement = Clarity::App.prompt("Excitement (1-5):").to_i
    #   motivation = Clarity::App.prompt("Motivation/why?")

    #   project = {
    #     name: name,
    #     summary: summary,
    #     effort: effort,
    #     excitement: excitement,
    #     motivation: motivation,
    #     status: 'inbox',
    #     created_at: Date.today.to_s
    #   }

    #   save(name, project)
    #   puts "Created project '#{name}'"
    # end

    # def finish(name)
    #   project = load(name)
    #   unless project
    #     warn "Project '#{name}' not found."
    #     exit 1
    #   end

    #   if project['status'] == 'finished'
    #     warn "Project '#{name}' is already finished."
    #     exit 1
    #   end

    #   confirm = Clarity::App.prompt("Mark project '#{name}' as finished? (y/n)")
    #   if confirm.downcase == 'y'
    #     project[:status] = 'finished'
    #     project[:finished_at] = Date.today.to_s

    #     save(name, project)
    #     puts "Project '#{name}' marked as finished."
    #   else
    #     puts "Cancelled."
    #   end
    # end
    #
    private

    def load_all_projects
      Dir.glob("#{PROJECTS_DIR}/*.json").map do |file|
        name = File.basename(file, '.json')
        build_project(name)
      end
    end

    def build_project(name)
      repo_path = File.join(PROJECTS_DIR, "#{name}.json")
      return nil unless File.exist?(repo_path)

      repo = JSON.parse(File.read(repo_path), symbolize_names: true)

      metadata_path = File.join(METADATA_DIR, "#{name}.json")
      metadata = if File.exist?(metadata_path)
                   JSON.parse(File.read(metadata_path), symbolize_names: true)
                 else
                   {
                     status: nil,
                     urgency: nil,
                     type: nil,
                     motivation: nil
                   }
                 end
      project = repo.merge(metadata)

      write_metadata_to_file(project) unless File.exist?(metadata_path)
      Clarity::Project.new(project)
    end

    def write_metadata_to_file(project)
      metadata = {
        status: project[:status],
        urgency: project[:urgency],
        type: project[:type],
        motivation: project[:motivation]
      }
      metadata_path = File.join(METADATA_DIR, "#{project[:name]}.json")
      begin
        FileUtils.mkdir_p(File.dirname(metadata_path))
        File.write(metadata_path, JSON.pretty_generate(metadata))
      rescue SystemCallError, IOError => e
        warn "Error: Failed to write metadata: #{e.message}"
      end
    end
  end
end
