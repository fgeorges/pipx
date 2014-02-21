# 
# XProcSpec attempt
#
# TODO: Rely on XprocSpec being on ../../xprocspec/, fix this.
# 
XPROCSPEC.dir=../../xprocspec
XPROCSPEC.rsrc=$(XPROCSPEC.dir)/xprocspec/src/main/resources
XPROCSPEC=$(XPROCSPEC.rsrc)/content/xml/xproc/xprocspec.xpl

pipx-parameter.html: pipx-parameter.xprocspec
	calabash \
	  -o html=$@ \
	  -o result=pipx-parameter-report.xml \
	  -o junit=pipx-parameter-junit.xml \
	  -i $< \
	  $(XPROCSPEC)

# 
# Custom attempt
# 
pipx-parameter-report.html: pipx-parameter-report.xml
	saxon -s:$< -xsl:format-report.xsl > $@

pipx-parameter-report.xml: pipx-parameter.xproc
	calabash $< > $@

pipx-parameter.xproc: pipx-parameter.xml
	saxon -s:$< -xsl:compile-suite.xsl > $@

clean:
	rm -f pipx-parameter.html
	rm -f pipx-parameter-report.xml
	rm -f pipx-parameter-junit.xml
	rm -f pipx-parameter-report.html
	rm -f pipx-parameter.xproc

.PHONY: clean
