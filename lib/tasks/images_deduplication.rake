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

    with_processing = model.column_names.include?('processing')
    processing_conditional = {}

    if with_processing
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
        LIMIT 1
      SQL
      parent = model.find(duplicate.fingerprint_parent_id) if duplicate

      # если дублей нет - берём первую с конца картинку
      unless parent && with_retry { parent.img.exists?(:original) }
        parent = model.
          where({fingerprint: fingerprint}.merge(processing_conditional)).
          where('fingerprint_parent_id IS NULL').
          order('id DESC').
          first

        # если и она без оригинала - сделаем ещё 10 попыток определить главную картинку
        if parent && with_retry { !parent.img.exists?(:original) }
          possible_parents = model.
            where({fingerprint: fingerprint}.merge(processing_conditional)).
            where('fingerprint_parent_id IS NULL').
            where('id != ?', parent.id).
            order('id DESC').
            limit(10)

          parent = possible_parents.find { |p| with_retry { p.img.exists?(:original) } }
        end
      end

      unless parent
        logger.info("Not found #{fingerprint} with original image!!!")
        next
      end

      logger.info("Found parent #{parent.id}.")

      unless parent.img_fingerprint
        parent.update_attribute(:img_fingerprint, Paperclip.io_adapters.for(parent.img.to_file(:original)).fingerprint)
      end

      i = 0

      model.
        where(fingerprint: fingerprint).
        where('fingerprint_parent_id IS NULL AND id != ?', parent.id).
        each_instance(cursor_options) do |image|
        image.processing = false if with_processing
        begin
          with_retry do
            image.img.clear
            image.img.flush_deletes
          end
          image.duplicate_from(parent)
          image.save!

          i += 1
          logger.info("Fingerprint: #{fingerprint}. Processed: #{i}.") if (i % 1000).zero?
        rescue => e
          logger.error("Error on update #{image.id}")
          raise e
        end
      end

      # приводим все существующие дубли к одному родителю
      model.
        where(fingerprint: fingerprint).
        where('fingerprint_parent_id IS NOT NULL AND fingerprint_parent_id != ?', parent.id).
        each_instance(cursor_options) do |image|
        begin
          image.duplicate_from(parent)
          image.save!

          i += 1
          logger.info("Fingerprint: #{fingerprint}. Processed: #{i}.") if (i % 1000).zero?
        rescue => e
          logger.error("Error on update #{image.id}")
          raise e
        end
      end

      logger.info("Finish process fingerprint #{fingerprint} with #{i} images.")
    end

    logger.info('FINISH')
  end

  desc 'Заполнение колонки img_fingerprint'
  task fill_img_fingerprint: :environment do
    model = ENV.fetch('DEDUPLICATION_MODEL_NAME').constantize
    logger = Logger.new(STDOUT).tap { |l| l.formatter = Logger::Formatter.new }
    i = j = k = l = 0

    cursor_options = {with_hold: true, connection: ActiveRecord::Base.on(:direct).connection, block_size: 1000}

    with_processing = model.column_names.include?('processing')
    processing_conditional = with_processing ? {processing: false} : {}

    logger.info('START')

    model.
      where(img_fingerprint: nil, fingerprint_parent_id: nil).
      where(processing_conditional).
      each_instance(cursor_options) do |image|
      unless with_retry { image.img.exists?(:original) }
        j += 1
        i += 1

        logger.info("#{i} original processed. Without file: #{j}. #{k} duplicate processed.") if (i % 1000).zero?

        next
      end

      img_fingerprint = Paperclip.io_adapters.for(image.img.to_file(:original)).fingerprint

      begin
        image.update_attribute(:img_fingerprint, img_fingerprint)
        k += model.
          where(img_fingerprint: nil, fingerprint_parent_id: image.id).
          update_all(img_fingerprint: img_fingerprint)
      rescue => e
        logger.error("Error on update #{image.id}")
        raise e
      end

      i += 1

      logger.info("#{i} original processed. Without file: #{j}. #{k} duplicate processed.") if (i % 1000).zero?
    end

    logger.info('Finish original images.')

    sql = <<-SQL
      SELECT id, img_fingerprint FROM #{model.quoted_table_name} image1
      WHERE img_fingerprint IS NOT NULL AND EXISTS (
        SELECT 1 FROM #{model.quoted_table_name} image2
        WHERE fingerprint_parent_id = image1.id AND img_fingerprint IS NULL
        LIMIT 1
      );
    SQL

    PostgreSQLCursor::Cursor.new(sql, cursor_options).each_row do |row|
      k += model.
        where(img_fingerprint: nil, fingerprint_parent_id: row['id']).
        update_all(img_fingerprint: row['img_fingerprint'])

      l += 1
      logger.info("#{i} original processed. Without file: #{j}. #{k} duplicate processed.") if (l % 1000).zero?
    end

    logger.info("#{i} original processed. Without file: #{j}. #{k} duplicate processed.")
    logger.info('FINISH')
  end

  def with_retry(count = 3)
    yield
  rescue
    raise if count.zero?
    sleep 1
    with_retry(count - 1) { yield }
  end
end
