namespace :images_deduplication do
  desc 'Удаление дублей картинок'
  task remove_duplicates: :environment do
    model = ENV.fetch('DEDUPLICATION_MODEL_NAME').constantize
    logger = Logger.new(STDOUT).tap { |l| l.formatter = Logger::Formatter.new }

    sql = <<-SQL
      SELECT * FROM (
        SELECT fingerprint, COUNT(*) AS img_count
        FROM #{model.quoted_table_name}
        WHERE fingerprint IS NOT NULL AND fingerprint_parent_id IS NULL GROUP BY fingerprint
      ) a
      WHERE img_count > 1
      ORDER BY img_count DESC;
    SQL

    cursor_options = {with_hold: true, connection: ActiveRecord::Base.on(:direct).connection, block_size: 1000}

    processing_conditional = {}

    if model.column_names.include?('processing')
      processing_conditional = {processing: false}
      processing_sql = <<-SQL
        AND EXISTS (SELECT 1 FROM #{model.quoted_table_name} b WHERE b.id = a.fingerprint_parent_id AND NOT processing)
      SQL
    end

    logger.info('START')

    PostgreSQLCursor::Cursor.new(sql, cursor_options).each_row do |row|
      fingerprint = row['fingerprint']
      logger.info("Start process fingerprint #{fingerprint} with #{row['img_count']} images.")

      # проверяем не существует ли уже родитель для таких картинок
      duplicate = model.find_by_sql(<<-SQL).first
        SELECT a.fingerprint_parent_id
        FROM #{model.quoted_table_name} a
        WHERE a.fingerprint = #{model.connection.quote(fingerprint)} AND a.fingerprint_parent_id IS NOT NULL
        #{processing_sql}
      SQL
      parent = model.find(duplicate.fingerprint_parent_id) if duplicate

      # если дублей нет - берём первую с конца картинку
      unless parent && parent.img.exists?(:original)
        parent = model.
          where({fingerprint: fingerprint}.merge(processing_conditional)).
          where('fingerprint_parent_id IS NULL').
          order('id DESC').
          first

        # если и она без оригинала - сделаем ещё 10 попыток определить главную картинку
        if parent && !parent.img.exists?(:original)
          possible_parents = model.
            where({fingerprint: fingerprint}.merge(processing_conditional)).
            where('fingerprint_parent_id IS NULL').
            where('id != ?', parent.id).
            order('id DESC').
            limit(10)

          parent = possible_parents.find { |p| p.img.exists?(:original) }
        end
      end

      unless parent
        logger.info("Not found #{fingerprint} with original image!!!")
        next
      end

      unless parent.img_fingerprint
        parent.update_attribute(:img_fingerprint, Paperclip.io_adapters.for(parent.img.to_file(:original)).fingerprint)
      end

      i = 0

      model.
        where(fingerprint: fingerprint).
        where('fingerprint_parent_id IS NULL AND id != ?', parent.id).
        each_instance(cursor_options) do |image|
        image.img.clear
        image.img.flush_deletes
        image.duplicate_from(parent)
        image.save!

        i += 1
        logger.info("Fingerprint: #{fingerprint}. Processed: #{i}.") if (i % 1000).zero?
      end

      # приводим все существующие дубли к одному родителю
      model.
        where(fingerprint: fingerprint).
        where('fingerprint_parent_id IS NOT NULL AND fingerprint_parent_id != ?', parent.id).
        each_instance(cursor_options) do |image|
        image.duplicate_from(parent)
        image.save!

        i += 1
        logger.info("Fingerprint: #{fingerprint}. Processed: #{i}.") if (i % 1000).zero?
      end

      logger.info("Finish process fingerprint #{fingerprint} with #{i} images.")
    end

    logger.info('FINISH')
  end

  desc 'Заполнение колонки img_fingerprint'
  task fill_img_fingerprint: :environment do
    model = ENV.fetch('DEDUPLICATION_MODEL_NAME').constantize
    logger = Logger.new(STDOUT).tap { |l| l.formatter = Logger::Formatter.new }
    i = 0

    cursor_options = {with_hold: true, connection: ActiveRecord::Base.on(:direct).connection, block_size: 1000}

    processing_conditional = model.column_names.include?('processing') ? {processing: false} : {}

    logger.info('START')

    model.where('img_fingerprint IS NULL').where(processing_conditional).each_instance(cursor_options) do |image|
      unless image.img.exists?(:original)
        i += 1

        logger.info("Processed #{i} images.") if (i % 1000).zero?

        next
      end

      img_fingerprint = Paperclip.io_adapters.for(image.img.to_file(:original)).fingerprint

      parent = model.find_original(img_fingerprint)

      if parent
        image.img.clear
        image.img.flush_deletes
        image.duplicate_from(parent)
        image.save!
      else
        image.update_attribute(:img_fingerprint, img_fingerprint)
      end

      i += 1

      logger.info("Processed #{i} images.") if (i % 1000).zero?
    end

    logger.info('FINISH')
  end
end
