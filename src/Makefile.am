# Sources for dirinstall

module_DATA = \
  modules/DirInstall.rb

client_DATA = \
  clients/inst_dirinstall_finish.rb \
  clients/dirinstall_options_proposal.rb \
  clients/dirinstall.rb \
  clients/inst_dirinstall.rb \
  clients/dirinstall_options.rb

yncludedir = @yncludedir@/dirinstall
ynclude_DATA = \
  include/dirinstall/ui.rb

desktop_DATA = \
  desktop/dirinstall.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common