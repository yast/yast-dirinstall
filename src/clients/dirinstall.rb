# encoding: utf-8

# File:	packager/inst_dir/instintodir.ycp
# Module:	System installation
# Summary:	Installation into  a directory
# Authors:	Anas Nashif <nashif@suse.de>
#
# $Id$
#
module Yast
  class DirinstallClient < Client
    def main
      Yast.import "Pkg"
      textdomain "dirinstall"

      Yast.import "CommandLine"
      Yast.import "PackageCallbacks"
      Yast.import "Wizard"
      Yast.import "DirInstall"
      Yast.import "PackageLock"
      Yast.import "Report"
      Yast.import "Progress"

      Yast.include self, "dirinstall/ui.rb"

      @cmdline_description = {
        "id"         => "dirinstall",
        # Command line help text for the dirinstall module
        "help"       => _(
          "Installation into Directory"
        ),
        "guihandler" => fun_ref(method(:StartDirInstall), "symbol ()")
      }

      CommandLine.Run(@cmdline_description)
    end

    def StartDirInstall
      # open the dialog
      Wizard.CreateDialog
      Wizard.SetDesktopIcon("sw_single")
      Wizard.SetDesktopTitle("dirinstall")
      Wizard.SetContents(_("Initializing..."), Empty(), "", false, true)

      DirInstall.SetStarted(false)

      # set YAST_IS_RUNNING to "instsys" to skip some actions in %post scripts (bnc#786837)
      Builtins.setenv("YAST_IS_RUNNING", "instsys")

      # check whether having the packager for ourselves
      return :abort if !PackageLock.Check


      stages = [
        # progress bar item
        _("Initialize the Software Manager"),
        # progress bar item
        _("Select Software"),
        # progress bar item
        _("Initialize the Target System")
      ]

      stages2 = [
        # progress bar item
        _("Initializing the Software Manager..."),
        # progress bar item
        _("Selecting Software..."),
        # progress bar item
        _("Initializing the Target System...")
      ]

      # progres bar label
      Progress.New(
        _("Initializing..."),
        " ",
        Ops.subtract(Builtins.size(stages), 1),
        # progres bar label
        stages,
        stages2,
        _("Please wait...")
      )


      Progress.NextStage

      # initializa the package manager
      old_src = -1
      new_src = -1

      Pkg.TargetFinish
      Pkg.SourceStartManager(true)

      Progress.NextStage

      prods = Pkg.ResolvableProperties("", :product, "")
      Builtins.y2milestone("Found products: %1", prods)

      if Builtins.size(prods) == 0
        # error report
        Report.Error(_("Could not read package information."))
        Wizard.CloseDialog
        return :abort
      end

      Builtins.foreach(prods) do |prod|
        # select all products for installation
        Pkg.ResolvableInstall(Ops.get_string(prod, "name", ""), :product)
      end 


      ret = Run()

      Progress.NextStage

      Builtins.y2milestone("Sequence returned %1", ret)
      DirInstall.UmountFilesystems

      DirInstall.FinishPackageManager if DirInstall.GetStarted

      Wizard.CloseDialog
      ret
    end
  end
end

Yast::DirinstallClient.new.main
