# Makefile.am for dirinstall/src

yncludedir = @yncludedir@/dirinstall

client_DATA =			\
	dirinstall.ycp		\
	dirinstall_auto.ycp	\
	dirinstall_proposal.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp

desktop_DATA =			\
	dirinstall.desktop

module_DATA =			\
	Dirinstall.ycp		\
	Dirinstall2.pm

# create a symlink for local build, #145327
dirinstall:
	ln -sf . $@
ycpchook = dirinstall

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
