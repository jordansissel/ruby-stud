Gem::Specification.new do |spec|
  spec.name = "stud"
  spec.version = "0.0.11"
  spec.summary = "stud - common code techniques"
  spec.description = "small reusable bits of code I'm tired of writing over " \
    "and over. A library form of my software-patterns github repo."

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
  
  spec.add_dependency("metriks") # for benchmark
  spec.add_dependency("ffi") # for benchmark to get cpu usage

  spec.add_development_dependency("rspec")
  spec.add_development_dependency("insist")
end

