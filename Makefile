# In case your system doesn't have any of these tools:
# https://pypi.python.org/pypi/xml2rfc
# https://github.com/Juniper/libslax/tree/master/doc/oxtradoc

draft = nmda-netconf.org
output_base = draft-ietf-netconf-nmda-netconf
examples =
trees = get-data.tree edit-data.tree
std_yang = ietf-netconf-datastores.yang
ex_yang =
references_src = references.txt
references_xml = references.xml

# ----------------------------
# Shouldn't need to modify anything below this line

ifeq (,$(draft))
possible_drafts = draft-*.xml draft-*.md draft-*.org
draft := $(lastword $(sort $(wildcard ${possible_drafts})))
endif

draft_base = $(basename ${draft})
draft_type := $(suffix ${draft})

ifeq (,${examples})
examples = $(wildcard ex-*.xml)
endif
load=$(patsubst ex-%.xml,ex-%.load,$(examples))

ifeq (,${std_yang})
std_yang := $(wildcard ietf*.yang)
endif
ifeq (,${ex_yang})
ex_yang := $(wildcard ex*.yang)
endif
yang := $(std_yang) $(ex_yang)

XML2RFC ?= xml2rfc
OXTRADOC ?= oxtradoc
IDNITS ?= idnits
PYANG ?= pyang

ifeq (,$(draft))
$(warning No file named draft-*.md or draft-*.xml or draft-*.org)
$(error Read README.md for setup instructions)
endif

current_ver := $(shell git tag | grep '${output_base}-[0-9][0-9]' | tail -1 | sed -e"s/.*-//")
ifeq "${current_ver}" ""
next_ver ?= 02
else
next_ver ?= $(shell printf "%.2d" $$((1$(current_ver)-99)))
endif
output = ${output_base}-${next_ver}

.PHONY: latest submit clean validate

submit: ${output}.txt

html: ${output}.html

idnits: ${output}.txt
	${IDNITS} $<

clean:
	-rm -f ${output_base}-[0-9][0-9].* ${references_xml} ${load}
	-rm -f *.dsrl *.rng *.sch ${draft_base}.fxml

.INTERMEDIATE: $(load)
%.load: %.xml
	 cat $< | awk -f fix-load-xml.awk > $@

.INTERMEDIATE: example-system.oper.yang
example-system.oper.yang: example-system.yang
	grep -v must $< > $@

validate: validate-std-yang validate-ex-yang

validate-std-yang:
	${PYANG} ${PYANGFLAGS} --ietf ${std_yang}

validate-ex-yang:
ifneq (,${ex_yang})
	${PYANG} ${PYANGFLAGS} --canonical --max-line-length 69 ${ex_yang}
endif

${references_xml}: ${references_src}
	${OXTRADOC} -m mkback $< > $@

ifeq (.xml,$(draft_type))
${output}.xml: ${draft}.xml
	sed -e"s/$(basename $<)-latest/$(basename $@)/" $< > $@

${output}.xml: back.xml $(trees) $(load) $(yang)
endif

${output}.xml : ${draft} ${references_xml} ${trees} ${yang}
	${OXTRADOC} -m outline-to-xml -n "${output}" $< > $@

${output}.txt: ${output}.xml
	${XML2RFC} $< -o $@ --text

.INTERMEDIATE: $(trees)
get-data.tree: ietf-netconf-datastores.yang
	${PYANG} ${PYANGFLAGS} -f tree --tree-line-length 68 \
	  --tree-path /get-data $< | awk '/rpcs/ { s=1; next;} \
	  s==0 { next; } {print}' > $@

edit-data.tree: ietf-netconf-datastores.yang
	${PYANG} ${PYANGFLAGS} -f tree --tree-line-length 68 \
	  --tree-path /edit-data $< | awk '/rpcs/ { s=1; next;} \
	  s==0 { next; } {print}' > $@

${output}.html: ${draft}
	@echo "Generating $@ ..."
	${OXTRADOC} -m html -n "${output}" $< > $@
