RAILS_ENV = test
BUNDLER_VERSION = 1.7.15
BUNDLE = RAILS_ENV=${RAILS_ENV} bundle _${BUNDLER_VERSION}_
BUNDLE_OPTIONS = --jobs=3 --quiet
RSPEC = rspec
APPRAISAL = appraisal

all: test

test: bundler appraisal
	${BUNDLE} exec ${APPRAISAL} ${RSPEC} spec 2>&1

bundler:
	gem list -i -v ${BUNDLER_VERSION} bundler > /dev/null || gem install bundler --no-ri --no-rdoc --version=${BUNDLER_VERSION}
	${BUNDLE} install ${BUNDLE_OPTIONS}

appraisal:
	${BUNDLE} exec ${APPRAISAL} install

clean:
	rm -f Gemfile.lock
	rm -rf gemfiles
