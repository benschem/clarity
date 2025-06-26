# frozen_string_literal: true

require 'date'

module Clarity
  class Project
    STATUSES = {
      deployed: '🚀',
      development: '🛠️',
      archived: '🗄️',
      paused: '⏸️',
      idea: '💡',
      abandoned: '☠️'
    }.freeze

    URGENCIES = {
      high: '‼️',
      medium: '❗️',
      low: '❕',
      none: '💤'
    }.freeze

    TYPES = {
      client: '💰',
      teaching: '👨🏻‍🏫',
      job: '👔',
      learning: '📚',
      personal: '🫵🏻'
    }.freeze

    MOTIVATIONS = {
      hot: '🔥',
      warm: '💪🏻',
      blocked: '⛔',
      cold: '🥶',
      dread: '💀',
      finished: '☑️'
    }.freeze

    STATUS_ORDER = STATUSES.keys.each_with_index.to_h.freeze
    URGENCY_ORDER = URGENCIES.keys.each_with_index.to_h.freeze
    TYPE_ORDER = TYPES.keys.each_with_index.to_h.freeze
    MOTIVATION_ORDER = MOTIVATIONS.keys.each_with_index.to_h.freeze

    SORT_OPTIONS = %w[name status urgency type motivation created_at pushed_at].freeze

    FILTERS = {
      status: STATUSES.keys.map(&:to_s),
      urgency: URGENCIES.keys.map(&:to_s),
      name: :text,
      type: TYPES.keys.map(&:to_s),
      description: :text,
      motivation: MOTIVATIONS.keys.map(&:to_s),
      languages: :text,
      full_name: :text,
      url: :text
    }.freeze

    attr_reader :name, :full_name, :url, :description, :languages, :total_lines, :created_at, :pushed_at
    attr_accessor :status, :urgency, :type, :motivation

    def initialize(attributes = {})
      @name = attributes[:name]
      @full_name = attributes[:full_name]
      @url = attributes[:url]
      @description = attributes[:description]
      @created_at = attributes[:created_at]
      @pushed_at = attributes[:pushed_at]
      @languages = attributes[:languages]
      @total_lines = attributes[:total_lines]
      @status = attributes[:status]
      @urgency = attributes[:urgency]
      @type = attributes[:type]
      @motivation = attributes[:motivation]
    end

    def created_days_ago
      date_ago(created_at)
    end

    def pushed_days_ago
      date_ago(pushed_at)
    end

    private

    def date_ago(timestamp)
      return nil unless timestamp

      (Date.today - Date.parse(timestamp.to_s)).to_i
    end
  end
end
