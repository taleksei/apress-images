# coding: utf-8

module Apress
  module Images
    class CropImagePresenter
      attr_reader :view

      # Public: Конструктор.
      #
      # view ActionView::Base - view контекст презентера.
      def initialize(view)
        @view = view
      end

      def show
        view.capture do
          view.render('apress/images/presenters/crop_image_show', presenter: self)
        end
      end
    end
  end
end
