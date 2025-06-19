# frozen_string_literal: true

# Bundler to setup Gems from Gemfile
require 'bundler/setup'

# Easily accept posix options and flags
require 'optparse'
require 'config/options_parser'

# Models
require 'models/github_repo_importer'
require 'models/project'

# Repositories
require 'repositories/project_repository'

# Views
require 'views/core'
require 'views/projects'

# Controllers
require 'controllers/projects_controller'
