SHELL=/bin/bash
TARGETS=$(patsubst %.jsonnet, %.json, $(wildcard dash*.jsonnet))
ALL_JSONNET=$(wildcard *.jsonnet)
PHONY_GOLDEN=$(patsubst %.jsonnet,generated/%.json,$(ALL_JSONNET))
PHONY_DIFF=$(patsubst %.jsonnet,%.diff,$(ALL_JSONNET))

all: $(TARGETS)

test: test-fmt generated-diff

test-fmt:
	jsonnet fmt --test $(ALL_JSONNET)
clean:
	rm -f $(TARGETS)

%.json: %.jsonnet
	jsonnet $(^) > $(@).tmp && mv $(@).tmp $(@) || rm -f $(@).tmp

generated-diff: $(PHONY_DIFF)

%.diff: %.jsonnet
	diff -u generated/$(*).json <(jsonnet $(<))

generated/%.json: %.jsonnet
	jsonnet $(<) > $(@)

generate: $(PHONY_GOLDEN)

.PRECIOUS: %.jsonnet generated/%.json
