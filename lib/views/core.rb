# frozen_string_literal: true

module Clarity
  class CoreView
    def self.prompt(question)
      print "#{question} "
      gets.chomp
    end
  end
end
