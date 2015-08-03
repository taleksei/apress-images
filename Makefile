RAILS_ENV = test
BUNDLE = RAILS_ENV=${RAILS_ENV} bundle
BUNDLE_OPTIONS = --jobs=2
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
	if ! gem list bundler -i > /dev/null; then \
	  gem install bundler; \
	fi
	${BUNDLE} install ${BUNDLE_OPTIONS}

appraisal:
	${BUNDLE} exec ${APPRAISAL} install
