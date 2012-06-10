GEMSPEC=$(shell ls *.gemspec | head -1)
VERSION=$(shell ruby -rubygems -e 'puts Gem::Specification.load("$(GEMSPEC)").version')
PROJECT=$(shell ruby -rubygems -e 'puts Gem::Specification.load("$(GEMSPEC)").name')
GEM=$(PROJECT)-$(VERSION).gem

.PHONY: test
test:
	bundle exec rspec

.PHONY: package
package: $(GEM)

# Always build the gem
.PHONY: $(GEM)
$(GEM):
	gem build $(PROJECT).gemspec

showdocs:
	yard server --plugin yard-tomdoc -r

clean:
	-rm -r .yardoc/ doc/ *.gem 

.PHONY: install
install: $(GEM)
	gem install $<

.PHONY: publish
publish: $(GEM)
	gem push $(GEM)
