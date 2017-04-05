require 'open_uri_redirections'

module Apress
  module Images
    module Extensions
      module IoAdapters
        module UriAdapter
          def download_content
            options = {
              allow_redirections: :safe,
              read_timeout: ::Rails.application.config.images.fetch(:http_read_timeout),
              open_timeout: ::Rails.application.config.images.fetch(:http_open_timeout)
            }

            open(@target, options)
          end
        end
      end
    end
  end
end
