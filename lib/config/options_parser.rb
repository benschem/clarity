# frozen_string_literal: true

module Clarity
  class OptionsParser
    VALID_ORDER_OPTIONS = %w[asc desc].freeze

    attr_reader :options

    def initialize
      @commands = {
        'sync': 'Sync from GitHub',
        'list': 'Show all projects',
        'show ID': 'Show a project by ID',
        'update ID': 'Update a project by ID',
        'filters': 'Show filter options for list command'
      }
      @valid_sort_options = Clarity::Project::SORT_OPTIONS
      @options = { filters: Hash.new { |h, k| h[k] = [] } }
      build_parser
    end

    def build_parser
      @parser = OptionParser.new do |opts|
        add_banner(opts)
        add_command_list(opts)

        opts.separator 'Options for list command (in order of operation):'
        add_filter_option(opts)
        add_sort_option(opts)
        add_order_option(opts)
        add_limit_option(opts)
        opts.separator ''

        opts.separator 'Options with no command'
        add_version_option(opts)
        add_help_option(opts)
      end
    end

    def parse!
      @parser.parse!
    end

    private

    def add_banner(opts)
      opts.banner = "Usage:\n> #{Clarity::CLI::PROGRAM_NAME} [command] ARG --[option] ARG ..."
      opts.separator ''
    end

    def add_command_list(opts)
      opts.separator 'Commands:'
      @commands.each do |command, description|
        opts.separator "    #{command.to_s.ljust(12)} #{description}"
      end
      opts.separator ''
    end

    def add_filter_option(opts)
      opts.on('--filter KEY=VALUE', 'Filter projects (can be repeated)') do |pair|
        key, value = pair.split('=', 2)
        if key && value
          @options[:filters][key] << value
        else
          warn 'Invalid filter format. Use --filter key=value'
          exit 1
        end
      end
    end

    def add_sort_option(opts)
      opts.on('-s', '--sort BY', String, "Sort projects by (#{@valid_sort_options.join(', ')})") do |by|
        unless @valid_sort_options.include?(by)
          warn "Can't sort by: #{by}"
          warn "Valid sort by options: #{@valid_sort_options.join(', ')}"
          exit 1
        end

        @options[:sort] = by
      end
    end

    def add_order_option(opts)
      opts.on('-o', '--order ORDER', String, 'Order projects (asc, desc)') do |order|
        unless VALID_ORDER_OPTIONS.include?(order)
          warn "Can't order by: #{order}"
          warn "Valid order options: #{VALID_ORDER_OPTIONS.join(', ')}"
          exit 1
        end

        @options[:order] = order
      end
    end

    def add_limit_option(opts)
      opts.on('-l', '--limit N', Integer, 'Limit output to N number of projects') do |n|
        @options[:limit] = n
      end
    end

    def add_version_option(opts)
      opts.on('-V', '--version', 'Print the version') do
        puts "#{Clarity::CLI::PROGRAM_NAME} #{Clarity::CLI::VERSION}"
        exit
      end
    end

    def add_help_option(opts)
      opts.on('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end
  end
end
