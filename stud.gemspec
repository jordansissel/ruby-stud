Gem::Specification.new do |spec|
  spec.name = "stud"
  spec.version = "0.0.23"
  spec.summary = "stud - common code techniques"
  spec.description = "small reusable bits of code I'm tired of writing over " \
    "and over. A library form of my software-patterns github repo."
  spec.license     = 'Apache License 2.0'
  
  files = []
  dirs = %w{lib}
  dirs.each do |dir|
    files += Dir["#{dir}/**/*"]
  end

  files << "LICENSE"
  files << "CHANGELIST"
  files << "README.md"

  spec.files = files
  spec.require_paths << "lib"

  spec.author = "Jordan Sissel"
  spec.email = "jls@semicomplete.com"
  spec.homepage = "https://github.com/jordansissel/ruby-stud"

  spec.add_development_dependency("rspec")
  spec.add_development_dependency("insist")
end

