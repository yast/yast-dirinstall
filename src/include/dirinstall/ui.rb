# encoding: utf-8

# File:	packager/inst_dir/instintodir.ycp
# Module:	System installation
# Summary:	Installation into  a directory
# Authors:	Anas Nashif <nashif@suse.de>
#
# $Id$
#
module Yast
  module DirinstallUiInclude
    def initialize_dirinstall_ui(include_target)
      Yast.import "Pkg"
      textdomain "dirinstall"

      Yast.import "Mode"
      Mode.SetMode("autoinst_config") # FIXME, messy
      Yast.import "Product"
      Mode.SetMode("normal") # FIXME, messy
      Yast.import "DirInstall"
      Yast.import "ProductControl"

      Yast.import "Installation"

      Yast.import "Wizard"
      Yast.import "Report"
      Yast.import "Progress"
    end

    def Run
      Builtins.y2milestone("current mode: %1", Mode.mode)
      DirInstall.InitProductControl
      Installation.dirinstall_installing_into_dir = true

      Progress.NextStage

      # check the package manager target
      Pkg.TargetFinish
      tmpdir = Convert.to_string(SCR.Read(path(".target.tmpdir")))
      tmpdir = Ops.add(tmpdir, "/target")
      SCR.Execute(path(".target.mkdir"), tmpdir)
      Pkg.TargetInit(tmpdir, true)

      wizard_mode = Mode.test ? "installation" : Mode.mode

      stage_mode = [{ "stage" => "normal", "mode" => wizard_mode }]
      ProductControl.AddWizardSteps(stage_mode)

      # Do log Report messages by default (bug 180862)
      Report.LogMessages(true)
      Report.LogErrors(true)
      Report.LogWarnings(true)

      # calling inst_proposal

      Installation.destdir = DirInstall.GetTarget
      Builtins.y2debug("target dir: %1", Installation.destdir)

      ret = ProductControl.Run

      if DirInstall.GetStarted
        # display a progress during exit
        stages = [
          # progress bar item
          _("Finish the Software Manager"),
          # progress bar item
          _("Clean Up")
        ]

        stages2 = [
          # progress bar item
          _("Finishing the Software Manager..."),
          # progress bar item
          _("Cleaning up...")
        ]

        # progres bar label
        Progress.New(
          _("Finishing..."),
          " ",
          Ops.subtract(Builtins.size(stages), 1),
          # progres bar label
          stages,
          stages2,
          _("Please wait...")
        )

        Progress.NextStage

        Pkg.SourceFinishAll
        Pkg.TargetFinish
      end

      Installation.destdir = "/"

      ret
    end
  end
end
