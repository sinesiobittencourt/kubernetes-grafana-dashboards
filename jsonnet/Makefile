TARGETS=$(patsubst %.jsonnet, %.json, $(wildcard *.jsonnet))

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

%.json: %.jsonnet
	jsonnet $(^) > $(@)

.PRECIOUS: %.jsonnet
