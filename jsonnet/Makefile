TARGETS=$(patsubst %.jsonnet, %.json, $(wildcard dash*.jsonnet))

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

%.json: %.jsonnet
	jsonnet $(^) > $(@)

.PRECIOUS: %.jsonnet
