# encoding: utf-8

# Module:	dirinstall_options_proposal.ycp
#
# Author:	Anas Nashif <nashif@suse.de>
#
# Purpose:     Proposal for dirinstall options
#
# $Id$
#
module Yast
  class DirinstallOptionsProposalClient < Client
    def main
      textdomain "dirinstall"

      Yast.import "DirInstall"
      Yast.import "HTML"

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      if @func == "MakeProposal"
        @force_reset = Ops.get_boolean(@param, "force_reset", false)
        @language_changed = Ops.get_boolean(@param, "language_changed", false)

        # call some function that makes a proposal here:
        #
        # DummyMod::MakeProposal( force_reset );


        if @force_reset
          DirInstall.SetTarget("/var/tmp/dirinstall")
          DirInstall.runme_at_boot = false
        end

        @tmp = []
        @color = "red"

        @ret = { "preformatted_proposal" => DirInstall.Propose }
      elsif @func == "AskUser"
        @has_next = Ops.get_boolean(@param, "has_next", false)

        # call some function that displays a user dialog
        # or a sequence of dialogs here:
        #

        @result = Convert.to_symbol(
          WFM.CallFunction("dirinstall_options", [true, @has_next])
        )

        # Fill return map

        @ret = { "workflow_sequence" => @result }
      elsif @func == "Description"
        # Fill return map.
        #
        # Static values do just nicely here, no need to call a function.

        @ret = {
          # this is a heading
          "rich_text_title" => _("Options"),
          # this is a menu entry
          "menu_title"      => _("&Options"),
          "id"              => "dirinstall_options_stuff"
        }
      end

      deep_copy(@ret)
    end
  end
end

Yast::DirinstallOptionsProposalClient.new.main
