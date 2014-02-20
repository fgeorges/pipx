pipx-parameter-report.html: pipx-parameter-report.xml
	saxon -s:$< -xsl:format-report.xsl > $@

pipx-parameter-report.xml: pipx-parameter.xproc
	calabash $< > $@

pipx-parameter.xproc: pipx-parameter.xml
	saxon -s:$< -xsl:compile-suite.xsl > $@

clean:
	rm pipx-parameter-report.html
	rm pipx-parameter-report.xml
	rm pipx-parameter.xproc

.PHONY: clean
