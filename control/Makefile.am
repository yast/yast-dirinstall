# Makefile.am for source/packager/src/config

controldir = $(yast2dir)/control

control_DATA = \
	dirinstall.xml

EXTRA_DIST = $(control_DATA)

# validate the control file in 'make check' run
check-local:
	xmllint --relaxng $(controldir)/control.rng --noout $(control_DATA)
