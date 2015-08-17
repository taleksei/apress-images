# coding: utf-8

require 'rails'
require('strong_parameters') if Rails::VERSION::MAJOR < 4
require 'paperclip'
require 'paperclip/watermark'
require 'action_view'
require 'haml'
require 'apress/images/engine'
require 'apress/images/version'

module Apress
  module Images
    # Public: определяет, является ли установленная версия paperclip старше v4.0
    #
    # Returns boolean
    def self.old_paperclip?
      Gem::Version.new(Paperclip::VERSION) < Gem::Version.new('4.0.0')
    end
  end
end
