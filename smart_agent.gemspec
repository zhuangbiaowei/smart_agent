require_relative "lib/smart_agent/version"

Gem::Specification.new do |spec|
  spec.name = "smart_agent"
  spec.version = SmartAgent::VERSION
  spec.authors = ["Zhuang Biaowei"]
  spec.email = ["zbw@kaiyuanshe.org"]

  spec.summary = "Intelligent agent framework with DSL and MCP integration"
  spec.description = "Build AI agents with declarative DSL and Model Context Protocol support"
  spec.homepage = "https://github.com/yourname/smart_agent"
  spec.license = "MIT"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_runtime_dependency "smart_prompt"
  spec.add_development_dependency "rspec", "~> 3.0"
end
