require 'open_uri_redirections'

module Apress
  module Images
    module Extensions
      module IoAdapters
        module UriAdapter
          def download_content
            options = {
              allow_redirections: :safe
            }

            open(@target, options)
          end
        end
      end
    end
  end
end
