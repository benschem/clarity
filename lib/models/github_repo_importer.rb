# frozen_string_literal: true

require 'io/console'
require 'json'
require 'fileutils'

require 'faraday' # Needed so Octokit.middleware exists
# Silence a warning about this middleware
begin
  Octokit.middleware.delete(Faraday::Request::Retry)
rescue StandardError
  nil
end
require 'octokit'

###
# GITHUB REPO IMPORTER
#
# Fetches all your Github repositories using their API and writes each one to JSON.
#
# RE: API Rate Limit
# The limit is 5,000 requests per hour per token and it resets every hour (on a rolling window).
#
# If the rate limit is exceeded you get a 403 Forbidden error - there are no charges.
# But you won't get anywhere near the limit anyway.
#
# With 50 repos, currently this code makes:
# 1 request (to get all repos)
# 50 repos × 1 requests (get repo languages) = 50 requests
# Total = 51 requests
# That's about ~1% of the hourly limit
###
module Clarity
  class GithubRepoImporter
    def self.call
      confirm_auth
      puts 'Attempting to fetch data from Github...'
      repo_data = fetch_repo_data
      repos = build_repos(repo_data)
      puts 'Writing data to files...'
      repos.each do |repo|
        write_to_file(repo)
      end
      puts 'Done.'
    end

    def self.confirm_auth
      config_path = File.expand_path('~/.clarityrc')
      if File.exist?(config_path)
        config = JSON.parse(File.read(config_path), symbolize_names: true)
        @github_access_token = config[:api_key]
      else
        @github_access_token = IO.console.getpass('Please set your Github access token:')
        File.write(config_path, JSON.pretty_generate({ api_key: @github_access_token }))
      end
    end

    def self.client
      # By default, Octokit does not timeout network requests
      # From docs - set a timeout in order to avoid Ruby’s Timeout module, which can kill your server
      Octokit.configure do |c|
        c.connection_options = {
          request: {
            open_timeout: 5, timeout: 5
          }
        }
      end

      Octokit::Client.new(access_token: @github_access_token).tap do |client|
        client.auto_paginate = true
      end
    end

    def self.fetch_repo_data
      with_retries { client.repos }
    rescue Octokit::Error => e
      warn "Error: Unable to fetch repos: #{e.class} - #{e.message}"
      []
    end

    def self.write_to_file(repo)
      output_file = File.join(Clarity::ProjectRepository::PROJECTS_DIR, "#{repo[:name]}.json")
      FileUtils.mkdir_p(File.dirname(output_file))
      File.write(output_file, JSON.pretty_generate(repo))
    rescue JSON::GeneratorError => e
      warn "Error: JSON generation failed while trying to write repo to file: #{e.class} - #{e.message}"
    rescue SystemCallError, IOError => e
      warn "Error: File write failed while trying to write repo to file: #{e.class} - #{e.message}"
    end

    def self.build_repos(repo_data)
      language_data = fetch_language_data(repo_data)
      repo_data.zip(language_data || []).each_with_index.map do |(repo, languages), index|
        {
          name: repo.name,
          full_name: repo.full_name,
          url: repo.html_url,
          description: repo.description,
          created_at: repo.created_at,
          pushed_at: repo.pushed_at,
          languages: languages || {},
          total_lines: (languages || {}).sum { |_, lines| lines }
        }
      end
    end

    def self.fetch_language_data(repos, pool_size: 5)
      queue = Queue.new
      # Add all repos to queue with their index to preserve order
      repos.each_with_index { |repo, i| queue << [i, repo] }

      # Placeholder for language data, matched by index
      results = Array.new(repos.size)

      workers = pool_size.times.map do
        Thread.new do
          # Create separate Octokit client per thread (not thread-safe to share)
          client = self.client

          loop do
            begin
              # Non-blocking pop, raises ThreadError when empty
              index, repo = queue.pop(true)
            rescue ThreadError
              break # queue is empty, thread is done
            end
            # Fetch language data and store in correct index
            results[index] = fetch_languages(repo, client)
          end
        end
      end

      begin
        # Wait for all threads to finish
        workers.each(&:join)
      rescue ThreadError => e
        warn "Error joining threads while getting languages: #{e.class} - #{e.message}"
        return []
      end

      results
    end

    def self.fetch_languages(repo, client)
      with_retries { client.languages(repo.full_name).to_h }
    rescue Octokit::Error => e
      warn "Github API error while fetching languages #{e.class} - #{e.message}"
      {}
    rescue StandardError => e
      warn "Unexpected error while fetching languages #{e.class} - #{e.message}"
      {}
    end

    def self.with_retries(limit: 3, delay: 1)
      attempts = 0
      begin
        yield
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        attempts += 1
        if attempts <= limit
          puts "Retrying due to network error: #{e.class} - #{e.message} (attempt #{attempts}/#{limit})"
          sleep delay
          retry
        else
          warn "Failed after #{limit} attempts: #{e.class} - #{e.message}"
          {}
        end
      end
    end
  end
end
