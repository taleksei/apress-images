module Apress
  module Images
    module Extensions
      module Interpolations
        module Deduplicable
          def id(attachment, _style_name)
            attachment.duplicate? ? attachment.instance.fingerprint_parent_id : attachment.instance.id
          end

          def id_partition(attachment, style_name)
            case id = id(attachment, style_name)
            when Integer
              ('%09d' % id).scan(/\d{3}/).join('/')
            when String
              ('%9.9s' % id).tr(' ', '0').scan(/.{3}/).join('/')
            end
          end
        end
      end
    end
  end
end
