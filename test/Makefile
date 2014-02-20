pipx-parameter-report.html: pipx-parameter-report.xml
	saxon -s:$< -xsl:format-report.xsl > $@

pipx-parameter-report.xml: pipx-parameter.xproc
	calabash $< > $@

pipx-parameter.xproc: pipx-parameter.xml
	saxon -s:$< -xsl:compile-suite.xsl > $@
