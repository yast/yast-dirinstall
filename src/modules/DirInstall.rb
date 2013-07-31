# encoding: utf-8

# File:	modules/DirInstall.ycp
# Package:	Instalation into a Directory
# Summary:	Instalation into a Directory  settings, input and output functions
# Authors:	Anas Nashif <nashif@suse.de>
#
# $Id$
#
require "yast"

module Yast
  class DirInstallClass < Module
    def main
      Yast.import "Pkg"
      textdomain "dirinstall"
      Yast.import "Mode"
      Yast.import "Stage"
      Yast.import "HTML"
      Yast.import "ProductControl"
      Yast.import "String"
      Yast.import "Installation"

      @runme_at_boot = false
      @makeimage = false
      @image_dir = ""
      @image_name = ""
      @use_autoyast_software = false
      @autoyast_software = ""


      @dirinstall_control_file = "/usr/share/YaST2/control/dirinstall.xml"

      @started = false

      @filesystems = [["/proc", "proc", "proc"], ["/sys", "sysfs", "sysfs"]]

      @mounted_fs = []
    end

    def SetStarted(status)
      @started = status
      Builtins.y2milestone("DirInstall started set to: %1", @started)

      nil
    end

    def GetStarted
      Builtins.y2milestone("DirInstall started: %1", @started)
      @started
    end

    def GetTargetChangeTime
      Installation.dirinstall_target_time
    end

    def SetTarget(tgt)
      if Installation.dirinstall_target != tgt
        Installation.dirinstall_target = tgt
        Installation.dirinstall_target_time = Builtins.time
      end

      nil
    end

    def GetTarget
      Installation.dirinstall_target
    end

    def InitProductControl
      if Stage.normal
        ProductControl.custom_control_file = @dirinstall_control_file

        if !ProductControl.Init
          Builtins.y2error(
            "control file %1 not found",
            ProductControl.custom_control_file
          )
        end
      else
        Installation.dirinstall_installing_into_dir = false
      end

      nil
    end

    def Propose
      color = "red"
      tmp = []
      # Proposal for dirinstall installation
      tmp = Builtins.add(
        tmp,
        Builtins.sformat(
          _("Target Directory: %1"),
          HTML.Colorize(Installation.dirinstall_target, color)
        )
      )

      # Proposal for backup during update
      tmp = Builtins.add(
        tmp,
        Builtins.sformat(
          _("Run YaST and SuSEconfig at First Boot: %1"),
          HTML.Colorize(
            @runme_at_boot ?
              # part of label in proposal
              _("Yes") :
              # part of label in proposal
              _("No"),
            color
          )
        )
      )
      # Proposal for dirinstall installation
      tmp = Builtins.add(
        tmp,
        Builtins.sformat(
          _("Create Image: %1"),
          HTML.Colorize(@makeimage ? _("Yes") : _("No"), color)
        )
      )
      if @use_autoyast_software
        # Proposal for dirinstall installation
        tmp = Builtins.add(
          tmp,
          Builtins.sformat(
            _("Load software selection from %1"),
            @autoyast_software
          )
        )
      end

      HTML.List(tmp)
    end

    def MountFilesystems
      @mounted_fs = []
      Builtins.foreach(@filesystems) do |descr|
        mp = Ops.get(descr, 0, "")
        dev = Ops.get(descr, 1, "")
        type = Ops.get(descr, 2, "")
        mp = Ops.add(Installation.dirinstall_target, mp)
        WFM.Execute(
          path(".local.bash"),
          Builtins.sformat("test -d '%1' || mkdir -p '%1'", String.Quote(mp))
        )
        WFM.Execute(
          path(".local.bash"),
          Builtins.sformat(
            "/bin/mount -t %1 %2 '%3'",
            type,
            dev,
            String.Quote(mp)
          )
        )
        @mounted_fs = Builtins.add(@mounted_fs, mp)
      end
      Builtins.y2milestone("Mounted filesystems: %1", @mounted_fs)

      nil
    end

    def UmountFilesystems
      Builtins.y2milestone("Mounted filesystems: %1", @mounted_fs)
      Builtins.foreach(@mounted_fs) do |mp|
        WFM.Execute(
          path(".local.bash"),
          Builtins.sformat("/bin/umount '%1'", String.Quote(mp))
        )
      end
      @mounted_fs = []

      nil
    end

    def FinishPackageManager
      Pkg.SourceFinishAll
      Pkg.TargetFinish

      nil
    end

    publish :variable => :runme_at_boot, :type => "boolean"
    publish :variable => :makeimage, :type => "boolean"
    publish :variable => :image_dir, :type => "string"
    publish :variable => :image_name, :type => "string"
    publish :variable => :use_autoyast_software, :type => "boolean"
    publish :variable => :autoyast_software, :type => "string"
    publish :variable => :dirinstall_control_file, :type => "string"
    publish :function => :SetStarted, :type => "void (boolean)"
    publish :function => :GetStarted, :type => "boolean ()"
    publish :function => :GetTargetChangeTime, :type => "integer ()"
    publish :function => :SetTarget, :type => "void (string)"
    publish :function => :GetTarget, :type => "string ()"
    publish :function => :InitProductControl, :type => "void ()"
    publish :function => :Propose, :type => "string ()"
    publish :function => :MountFilesystems, :type => "void ()"
    publish :function => :UmountFilesystems, :type => "void ()"
    publish :function => :FinishPackageManager, :type => "void ()"
  end

  DirInstall = DirInstallClass.new
  DirInstall.main
end
