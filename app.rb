#!/usr/bin/env ruby

# ^ Tells the OS how to execute the file when run directly from the terminal.
# Uses the Ruby in $PATH

require 'json'
require 'fileutils'
require 'date'

PROJECTS_DIR = File.expand_path('~/.clarity/projects')

def usage
  puts <<~USAGE
    Usage: clarity COMMAND [ARGS]

    Commands:
      list               List all projects
      new NAME           Create a new project
      finish NAME        Mark project as finished
      help                Prints this message
  USAGE
  exit 1
end

def list_projects
  projects = Dir.glob("#{PROJECTS_DIR}/*.json").map do |file|
    JSON.parse(File.read(file), symbolize_names: true)
  end

  if projects.empty?
    puts "No projects found."
    return
  end

  projects.each do |project|
    status = project['status']
    name = project['name']
    summary = project['summary']
    puts "[#{status}] #{name} - #{summary}"
  end
end

def new_project(name)
  if load_project(name)
    puts "Project '#{name}' already exists."
    exit 1
  end

  summary = prompt("Summary:")
  effort = prompt("Estimated effort (e.g. 1hr, weekend):")
  excitement = prompt("Excitement (1-5):").to_i
  motivation = prompt("Motivation/why?")

  project = {
    name: name,
    summary: summary,
    effort: effort,
    excitement: excitement,
    motivation: motivation,
    status: 'inbox',
    created_at: Date.today.to_s
  }

  save_project(name, project)
  puts "Created project '#{name}'"
end

def finish_project(name)
  project = load_project(name)
  unless project
    puts "Project '#{name}' not found."
    exit 1
  end

  if project['status'] == 'finished'
    puts "Project '#{name}' is already finished."
    exit 1
  end

  confirm = prompt("Mark project '#{name}' as finished? (y/n)")
  if confirm.downcase == 'y'
    project[:status] = 'finished'
    project[:finished_at] = Date.today.to_s

    save_project(name, project)
    puts "Project '#{name}' marked as finished."
  else
    puts "Cancelled."
  end
end

def load_project(name)
  path = File.join(PROJECTS_DIR, "#{name}.json")
  return nil unless File.exist?(path)

  JSON.parse(File.read(path), symbolize_names: true)
end

def save_project(name, data)
  path = File.join(PROJECTS_DIR, "#{name}.json")
  File.write(path, JSON.pretty_generate(data))
end

def prompt(question)
  print "#{question} "
  gets.chomp
end

command = ARGV.shift
case command
when 'new'
  name = ARGV.shift
  usage unless name

  new_project(name)
when 'list'
  list_projects
when 'finish'
  name = ARGV.shift
  usage unless name

  finish_project(name)
else
  usage
end
