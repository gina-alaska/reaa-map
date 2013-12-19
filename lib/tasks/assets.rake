namespace :assets do
  desc 'Fix asset paths'
  task :resolve_asset_paths do
    # Resolve relative paths in CSS
    Dir['vendor/assets/bower_components/**/*.css'].each do |filename|
      contents = File.read(filename)
      # http://www.w3.org/TR/CSS2/syndata.html#uri
      url_regex = /url\(\s*['"]?(?![a-z]+:)([^'"\)]*)['"]?\s*\)/

      # Resolve paths in CSS file if it contains a url
      if contents =~ url_regex
        directory_path = Pathname.new(File.dirname(filename))
          .relative_path_from(Pathname.new('vendor/assets/bower_components'))

        # Replace relative paths in URLs with Rails asset_path helper
        new_contents = contents.gsub(url_regex) do |match|
          relative_path = $1
          image_path = directory_path.join(relative_path).cleanpath
          puts "#{match} => #{image_path}"

          "url(<%= asset_path '#{image_path}' %>)"
        end

        # Replace CSS with ERB CSS file with resolved asset paths
        FileUtils.rm(filename)
        File.write(filename + '.erb', new_contents)
      end
    end
  end  
end

Rake::Task['assets:precompile'].enhance ['assets:resolve_asset_paths']