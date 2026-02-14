.PHONY: base superpowers oh-my-opencode ralph all

base:
	docker build -t opencode-base base/

superpowers: base
	docker build -t opencode-superpowers superpowers/

oh-my-opencode: base
	docker build -t opencode-oh-my-opencode oh-my-opencode/

ralph: base
	docker build -t opencode-ralph ralph/

all: superpowers oh-my-opencode ralph

test:
	./tests/run-all.sh

test-dockerfiles:
	./tests/lint-dockerfiles.sh

test-scripts:
	./tests/lint-scripts.sh

test-json:
	./tests/validate-json.sh
