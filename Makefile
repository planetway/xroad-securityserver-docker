build:
	cd examples/single && docker-compose build

up-single:
	cd examples/single && docker-compose up

test:
	perl tests/test.pl
