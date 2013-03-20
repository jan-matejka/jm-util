#! /bin/sh

usage() {
	echo "Run inside the directory with xml files"
}

main() {
	for f in *.xml; do
		echo $f
		xsltproc -o ${f%.xml}.html --nonet --stringparam funcsynopsis.style ansi custom-html.xsl $f
	done
}