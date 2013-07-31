# encoding: utf-8

# File:
#   clients/inst_dirinstall_finish.ycp
#
# Summary:
#   Close dir installation
#
# Authors:
#   Anas Nashif <nashif@suse.de>
#
# $Id$
#
module Yast
  class InstDirinstallFinishClient < Client
    def main
      Yast.import "Pkg"
      textdomain "dirinstall"
      Yast.import "DirInstall"
      Yast.import "Installation"
      Yast.import "Directory"
      Yast.import "Progress"
      Yast.import "Mouse"
      Yast.import "Keyboard"
      Yast.import "Language"
      Yast.import "Timezone"
      Yast.import "Console"
      Yast.import "RunlevelEd"
      Yast.import "String"

      @progress_stages = [
        # progress stages
        _("Finalize system configuration"),
        # progress stages
        _("Prepare system for initial boot")
      ]

      @progress_length = 2
      if DirInstall.makeimage
        # progress stage
        @progress_stages = Builtins.add(
          @progress_stages,
          _("Create image file")
        )
        @progress_length = Ops.add(@progress_length, 1)
      end

      @progress_descriptions = []

      # help text
      @help_text = _("<p>Please wait while the system is being configured.</p>")

      Progress.New(
        # Headline for last dialog of base installation: Install LILO etc.
        _("Finishing Directory Installation"),
        "", # Initial progress bar label - not empty (reserve space!)
        @progress_length, # progress bar length
        @progress_stages,
        @progress_descriptions,
        @help_text
      )


      Progress.NextStage
      # progress title
      Progress.Title(_("Configuring installed system"))

      Progress.NextStage

      Builtins.y2milestone("Re-starting SCR on %1", Installation.destdir)
      Installation.scr_handle = WFM.SCROpen(
        Ops.add(Ops.add("chroot=", Installation.destdir), ":scr"),
        false
      )
      Installation.scr_destdir = "/"
      WFM.SCRSetDefault(Installation.scr_handle)

      # re-init tmpdir from new SCR !
      Directory.ResetTmpDir
      @tmpdir = Directory.tmpdir

      if DirInstall.runme_at_boot
        @runme_at_boot = Ops.add(Directory.vardir, "/runme_at_boot")
        if !SCR.Write(path(".target.string"), @runme_at_boot, "")
          Builtins.y2error("Couldn't create target %1", @runme_at_boot)
        end
      end

      if SCR.Execute(path(".target.bash"), "/sbin/ldconfig") != 0
        Builtins.y2error("ldconfig failed\n")
      end

      SCR.Execute(path(".target.mkdir"), Installation.sourcedir)
      Mouse.Save
      Timezone.Save
      Language.Save
      Keyboard.Save
      Console.Save

      @runlevel = RunlevelEd.default_runlevel == "" ?
        3 :
        Builtins.tointeger(RunlevelEd.default_runlevel)
      Builtins.y2milestone("setting default runlevel to %1", @runlevel)
      SCR.Write(
        path(".etc.inittab.id"),
        Builtins.sformat("%1:initdefault:", @runlevel)
      )
      SCR.Write(path(".etc.inittab"), nil)

      Pkg.SourceCacheCopyTo(Installation.destdir)

      # disable some services - they are useless and usually failing in UML/Xen VM
      @disable_services = ["kbd", "acpid"]
      Builtins.foreach(@disable_services) do |s|
        disabled = Convert.to_integer(
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("/sbin/insserv -r %1", s)
          )
        )
        Builtins.y2milestone(
          "insserv - service %1 exit status: %2",
          s,
          disabled
        )
      end 


      # Stop SCR on target
      WFM.SCRClose(Installation.scr_handle)
      # umount /proc and /sys before creating image (otherwise tar may fail)
      DirInstall.UmountFilesystems

      if DirInstall.makeimage && DirInstall.image_dir != "" &&
          DirInstall.image_name != ""
        Progress.NextStage
        @cmd = Builtins.sformat(
          "cd '%1' && tar -zcf '%2' . && cd - ",
          String.Quote(DirInstall.GetTarget),
          String.Quote(
            Ops.add(
              Ops.add(Ops.add(DirInstall.image_dir, "/"), DirInstall.image_name),
              ".tgz"
            )
          )
        )
        Builtins.y2debug("cmd: %1", @cmd)
        # progress title
        Progress.Title(_("Building directory image..."))
        WFM.Execute(path(".local.bash"), @cmd)
      end

      Progress.Finish
      :next
    end
  end
end

Yast::InstDirinstallFinishClient.new.main
