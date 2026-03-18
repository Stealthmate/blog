DOT_FILES=$(wildcard assets/*.dot)
DOT_SVG_FILES=$(subst .dot,.svg,$(DOT_FILES))

$(DOT_SVG_FILES): %.svg: %.dot
	dot -Tsvg -o $@ $<