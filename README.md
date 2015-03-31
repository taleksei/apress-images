# Apress::Images

[![Dolly](http://dolly.railsc.ru/badges/abak-press/apress-images/master)](http://dolly.railsc.ru/projects/83/builds/latest/?ref=master)

Предоставляет функционал для загрузки и прикрепления изображений

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apress-images'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apress-images

## Usage

```ruby

# Example 1
# Use Imagebale module
class Avatar < ActiveRecord::Base
  # Define custom resizing
  def self.attachment_options
    {
      styles: {
        thumb: {geometry: '320x240>'}
      }
    }
  end

  # Note: it should be in bottom
  include Apress::Images::Imageble
end

# Example 2
# Use Imagebale module with resizing in background
class Avatar < ActiveRecord::Base
  # Define custom resizing
  def self.attachment_options
    {
      styles: {
        thumb: {geometry: '320x240>'}
      }
    }
  end

  include Apress::Images::Imageble
  include Apress::Images::BackgroundProcessing
end

# Example 3
# Use abstract Image model (with default styles and background resizing)
class Avatar < Apress::Images::Image
end

```

## Contributing

1. Fork it ( https://github.com/abak-press/apress-images/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
