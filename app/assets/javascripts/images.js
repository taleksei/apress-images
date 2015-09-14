/*
* Универсальный модуль для загрузки картинок.
* app.config.images {
*   maxFileSize - по умолчанию 2
*   maxFilesCount - по умолчанию 1
*   sizeType - по умолчанию 'medium'
*   uploadData: {
*     model
*     'subject_type'
*     'subject_id'
*   }
*   multiple - по умолчанию false
* }
* */
app.modules.images = (function(self) {
  var
    _options = {
      maxFileSize: app.config.images.maxFileSize || 2,
      maxFilesCount: app.config.images.maxFilesCount || 1,
      processingTime: 2000,
      selectors: {
        imagesContainer: '.js-images-container',
        fileInput: '.js-input-file-image',
        buttonUpload: '.js-upload-image',
        visibleImages: '.js-image:visible',
        imageRow: '.js-image-row',
        imagesWrapper: '.js-images-wrapper'
      }
    },
    _images = [],
    _process = false,
    _$imagesContainer;

  _images.add = function(params) {
    this.push(params);
    _processing();
  };

  function _processing() {
    var images = $.merge([], _images);

    if (_process || !images.length) {
      return false;
    }

    _process = true;
    $.ajax({
      url: app.config.images.previewUrl,
      data: {
        ids: images,
        model: app.config.images.uploadData.model || null,
        style: app.config.images.sizeType || 'medium'
      },
      success: function(response) {
        _process = false;
        $.each(response, function() {
          var id = Object.keys(this)[0];
          if (this[id] === 'processing') {
            _images.push(id);
          } else {
            $('.js-image[data-id="' + id + '"]').attr({src: this[id]});
          }
        });
        _images.length && setTimeout(_processing, _options.processingTime);
      },
      error: function() {
        _process = false;
        $.merge(_images, images);
        $doc.trigger('imageProcessingFail:images', _$imagesContainer);
      }
    });
    _images.splice(0, _images.length);
  }

  function _uploadFiles(files) {
    FileAPI.upload({
      url: app.config.images.uploadUrl,
      data: app.config.images.uploadData || null,
      files: {'images[]': files},
      upload: function() {
        _$imagesContainer.find(_options.selectors.buttonUpload).prop({disabled: true});
      },
      filecomplete: function(err, xhr) {
        if (!err) {
          var previewImage = JSON.parse(xhr.responseText).ids[0];
          _images.add(previewImage);
          $doc.trigger('imageUploaded:images', {image: previewImage, container: _$imagesContainer});
        } else {
          $doc.trigger('imageUploadFail:images', _$imagesContainer);
        }
      },
      complete: function() {
        $(_options.selectors.fileInput).attr({value: ''});
        _$imagesContainer.find(_options.selectors.buttonUpload).prop({disabled: false});
      }
    });
  }

  function _loadFiles(files) {
    $doc.trigger('imageStartLoading:images', _$imagesContainer);
    FileAPI.filterFiles(files, function(file) {
      if (/^image/.test(file.type)) {
        var fileSizeIsNormal = file.size <= _options.maxFileSize * FileAPI.MB;
        if (!fileSizeIsNormal) {
          $doc.trigger('imageTooBig:images');
        }
        return fileSizeIsNormal;
      }
    }, function(files) {
      if (files.length) {
        if (_isImagesLimitExceeds(files)) {
          $doc.trigger('imageLimitExceeds:images', _$imagesContainer);
          files = files.slice(0, _options.maxFilesCount - (files.length + _getImagesCount()));
        }
        files.length && _uploadFiles(files);
      }
    });
  }

  function _getImagesCount() {
    return _$imagesContainer.find(_options.selectors.visibleImages).length;
  }

  function _isImagesLimitExceeds(files) {
    return files.length + _getImagesCount() > _options.maxFilesCount;
  }

  function _setContainer(el) {
    _$imagesContainer = $($(el).data('container'));
  }

  function _listener() {
    $doc.on('click', _options.selectors.buttonUpload, function(event) {
      _setContainer(this);
      $(_options.selectors.fileInput).click();
      event.preventDefault();
    });

    FileAPI.event.on($(_options.selectors.fileInput)[0], 'change', function(event) {
      _loadFiles(FileAPI.getFiles(event));
    });

    if (FileAPI.support.dnd) {
      $(_options.selectors.imagesWrapper).dnd($.noop, function(files) {
        _setContainer(this);

        if (_isImagesLimitExceeds(files)) {
          $doc.trigger('imageLimitExceeds:images', _$imagesContainer);
          files = files.slice(0, _options.maxFilesCount - (files.length + _getImagesCount()));
        }

        files.length && _uploadFiles(files);
      });
    }
  }

  self.load = function() {
    _listener();
  };

  return self;
}(app.modules.images || {}));
