# TODO: Depends on XProcDoc to be in ../xprocdoc/.
api:
	calabash \
	    -i src/pipx.xpl \
	    ../xprocdoc/xprocdoc.xpl \
	    product=PipX \
	    input-base-uri=file:`pwd`/ \
	    output-base-uri=file:`pwd`/website/api/

.PHONY: api
