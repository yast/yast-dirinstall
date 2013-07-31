# encoding: utf-8

# Module:	inst_dirinstall.ycp
#
# Authors:	Anas Nashif<nashif@suse.de>
#
# Purpose:	Install into directory
#
# $Id$
module Yast
  class InstDirinstallClient < Client
    def main
      Yast.import "Pkg"
      textdomain "dirinstall"

      Yast.import "DirInstall"
      Yast.import "PackageSlideShow"
      Yast.import "String"

      DirInstall.SetStarted(true)

      Pkg.TargetFinish
      DirInstall.MountFilesystems

      # create /dev/zero and /dev/null devices in the target directory,
      # some packages require them in the postinstall script
      SCR.Execute(
        path(".target.bash"),
        Builtins.sformat(
          "mkdir -p '%1/dev'",
          String.Quote(DirInstall.GetTarget)
        )
      )
      SCR.Execute(
        path(".target.bash"),
        Builtins.sformat(
          "mknod -m 666 '%1/dev/zero' c 1 5",
          String.Quote(DirInstall.GetTarget)
        )
      )
      SCR.Execute(
        path(".target.bash"),
        Builtins.sformat(
          "mknod -m 666 '%1/dev/null' c 1 3",
          String.Quote(DirInstall.GetTarget)
        )
      )

      # initialize the slideshow
      PackageSlideShow.InitPkgData(false)


      :next
    end
  end
end

Yast::InstDirinstallClient.new.main
