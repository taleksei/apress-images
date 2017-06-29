# coding: utf-8

module Apress
  module Images
    # Сервис очистки и транслитерации имени файла
    class FilenameCleaner
      def call(filename)
        extname = File.extname(filename)
        fname = File.basename(filename, extname)
        fname.scrub!('')
        fname = Addressable::URI.unescape(fname)
        fname = Russian.transliterate(fname)
        fname.gsub!(/[^\w-]/, '_')
        new_filename = "#{fname}#{extname}"
        if new_filename.length > 255
          new_filename[(new_filename.length - 255)..-1]
        else
          new_filename
        end
      end
    end
  end
end
