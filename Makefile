.PHONY: clean init build test dist realclean

SRC_FILES := $(wildcard src/*.coffee)
COFFEE := `npm bin`/coffee

dist: clean init build test

clean:
	rm -rf lib

realclean: clean
	rm -rf node_modules

init: node_modules/package.d

node_modules/package.d: package.json
	npm install
	touch node_modules/package.d

build: $(SRC_FILES)
	$(COFFEE) -o lib -c src

test:
