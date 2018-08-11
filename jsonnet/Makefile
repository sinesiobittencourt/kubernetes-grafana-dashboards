SHELL=/bin/bash
TARGETS=$(patsubst %.jsonnet, %.json, $(wildcard dash*.jsonnet))
ALL_JSONNET=$(wildcard *.jsonnet)
PHONY_GOLDEN=$(patsubst %.jsonnet,golden/%.json,$(ALL_JSONNET))
PHONY_DIFF=$(patsubst %.jsonnet,%.diff,$(ALL_JSONNET))

all: $(TARGETS)

test: test-fmt golden-diff

test-fmt:
	jsonnet fmt --test $(ALL_JSONNET)
clean:
	rm -f $(TARGETS)

%.json: %.jsonnet
	jsonnet $(^) > $(@).tmp && mv $(@).tmp $(@) || rm -f $(@).tmp

golden-diff: $(PHONY_DIFF)

%.diff: %.jsonnet
	diff -u golden/$(*).json <(jsonnet $(<))

golden/%.json: %.jsonnet
	jsonnet $(<) > $(@)

gen-golden: $(PHONY_GOLDEN)

.PRECIOUS: %.jsonnet golden/%.json
