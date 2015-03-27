# coding: utf-8

Rails.application.routes.draw do
  scope constraints: {domain: :current}, module: 'apress/images' do
    post 'images' => 'images#upload', as: :images_upload
    get 'images/previews' => 'images#previews', as: :preview_images
  end
end
