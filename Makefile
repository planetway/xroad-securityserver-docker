build:
	cd examples/single && docker-compose build

up-single:
	cd examples/single && docker-compose up

down-single:
	cd examples/single && docker-compose down -v

test:
	perl tests/test.pl
	tests/examples.sh
