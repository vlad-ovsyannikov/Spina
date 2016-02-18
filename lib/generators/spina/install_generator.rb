module Spina
  class InstallGenerator < Rails::Generators::Base

    source_root File.expand_path("../templates", __FILE__)

    def create_initializer_file
      template 'config/initializers/spina.rb'
    end

    def add_route
      return if Rails.application.routes.routes.detect { |route| route.app == Spina::Engine }
      route "mount Spina::Engine => '/'"
    end

    def copy_migrations
      rake 'spina:install:migrations'
    end

    def run_migrations
      rake 'db:migrate'
    end

    def create_account
      return if Account.exists? && !no?('An account already exists. Skip? [Yn]')
      name = ask('What would you like to name your website?')
      account = Account.first_or_create.update_attribute(:name, name)
    end

    def set_theme
      account = Account.first
      return if account.theme.present? && !no?("Theme '#{account.theme} is set. Skip? [Yn]")

      theme = begin
                theme = account.theme || 'default'
                theme = ask("What theme do you want to use? (default/demo) [#{theme}]").presence || theme
              end until theme.in? ['default', 'demo']

      account.update_attribute(:theme, theme)

      template "config/initializers/themes/#{theme}.rb"
      directory "app/assets/stylesheets/#{theme}"
      directory "app/views/#{theme}"
      directory "app/views/layouts/#{theme}"
      directory "app/views/layouts/#{theme}"
    end


    def create_user
      return if User.exists? && !no?('A user already exists. Skip? [Yn]')
      email = ask('Please enter an email address for your first user:')
      password = ask('Create a temporary password:', echo: false)
      User.create name: 'admin', email: email, password: password, admin: true
    end

    def bootstrap_spina
      rake 'spina:bootstrap'
    end

    def seed_demo_content
      theme_name = Account.first.theme
      if theme_name == 'demo' && !no?('Seed example content? [Yn]')

        current_theme = ::Spina.themes.find { |theme| theme.name == theme_name }
        if (page = Spina::Page.find_by(name: 'demo'))
          page.page_parts.clear
          parts = current_theme.config.page_parts.map { |page_part| page.page_part(page_part) }
          parts.each do |part|
            case part.partable_type
            when 'Spina::Line' then part.partable.content = 'This is a single line'
            when 'Spina::Text' then part.partable.content = '<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>'
            when 'Spina::Photo' then part.partable.remote_file_url = 'https://unsplash.it/300/200?random'
            when 'Spina::PhotoCollection'
              5.times { part.partable.photos.build(remote_file_url: 'https://unsplash.it/300/200?random') }
            # when 'Spina::Structure'
            #   part.partable.structure_items.build({ name: 'title', title: 'Title', structure_partable_type: 'Spina::Line' })
            #   part.partable.structure_items.build({ name: 'description', title: 'Description', structure_partable_type:  'Spina::Text' })
            when 'Spina::Color' then part.partable.content = '#6865b4'
            end
          end
          page.save
        end
      end
    end

  end
end
