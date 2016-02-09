# coding: utf-8
namespace :garbage_collector do
  desc 'Очистка мусорных картинок'
  task :images => :environment do
    Apress::Images::GarbageCollectorService.new.call
  end
end
