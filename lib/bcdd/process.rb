# frozen_string_literal: true

require 'bcdd/result'
require 'bcdd/contract'

require_relative 'process/version'

module BCDD
  class Process
    Error = Class.new(::StandardError)
  end
end
