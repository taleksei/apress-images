RAILS_ENV = test
BUNDLE_VERSION = 1.7.15
BUNDLE = RAILS_ENV=${RAILS_ENV} bundle _${BUNDLE_VERSION}_
BUNDLE_OPTIONS = --jobs=3 --quiet
RSPEC = rspec
APPRAISAL = appraisal

all: test

test: configs bundler appraisal
	${BUNDLE} exec ${APPRAISAL} ${RSPEC} spec 2>&1

define DATABASE_YML
test:
  adapter: postgresql
  database: docker
  username: docker
  host: localhost
  min_messages: warning
endef
export DATABASE_YML

configs:
	echo "$${DATABASE_YML}" > spec/internal/config/database.yml

bundler:
	gem list bundler | grep '^bundler\s.*' > /dev/null || gem install bundler --no-ri --no-rdoc --version=${BUNDLE_VERSION}
	${BUNDLE} install ${BUNDLE_OPTIONS}

appraisal:
	${BUNDLE} exec ${APPRAISAL} install
