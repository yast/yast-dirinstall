# encoding: utf-8

# Module:	dirinstall_options.ycp
#
# Authors:	Anas Nashif <nashif@suse.de>
#
# Purpose:	Ask the user for various options for dir install.
# $Id$
module Yast
  class DirinstallOptionsClient < Client
    def main
      Yast.import "Pkg"
      Yast.import "UI"
      textdomain "dirinstall"

      Yast.import "DirInstall"
      Yast.import "Installation"
      Yast.import "Wizard"
      Yast.import "Popup"
      Yast.import "Label"
      Yast.import "Profile"
      Yast.import "AutoinstSoftware"
      Yast.import "Report"

      # screen title for installation into directory options
      @title = _("Directory Install Options")

      # build and show dialog

      Wizard.OpenAcceptDialog

      @contents = HVSquash(
        VBox(
          # text entry
          Left(
            TextEntry(
              Id(:target),
              _("&Root Directory (not \"/\"):"),
              DirInstall.GetTarget
            )
          ),
          # check box
          Left(
            CheckBox(
              Id(:suseconfig),
              _("Run &YaST and SuSEconfig on First Boot"),
              DirInstall.runme_at_boot
            )
          ),
          Left(
            CheckBox(
              Id(:use_autoyast),
              Opt(:notify),
              _("Get Software Selection from AutoYaST Profile"),
              DirInstall.use_autoyast_software
            )
          ),
          VSquash(
            HBox(
              # text entry
              TextEntry(
                Id(:autoyast),
                _("&AutoYaST Profile"),
                DirInstall.autoyast_software
              ),
              VBox(
                VSpacing(),
                # push button
                Bottom(PushButton(Id(:open_profile), Label.BrowseButton))
              )
            )
          ),
          # check box
          Left(
            CheckBox(
              Id(:makeimage),
              Opt(:notify),
              _("Create Ima&ge"),
              DirInstall.makeimage
            )
          ),
          # text entry
          Left(
            TextEntry(Id(:imagename), _("Ima&ge Name:"), DirInstall.image_name)
          ),
          VSquash(
            HBox(
              # text entry
              TextEntry(
                Id(:imagedir),
                _("&Image Directory:"),
                DirInstall.image_dir
              ),
              VBox(
                VSpacing(),
                # push button
                Bottom(PushButton(Id(:open_dir), _("Select &Directory")))
              )
            )
          )
        )
      )

      # help text for dirinstall options 1/2
      @help_text = _(
        "<p>Choose a directory to which to install. Depending on the software selection, make sure\nenough space is available.</p>\n"
      )
      # help text for dirinstall options 2/2
      @help_text = Ops.add(
        @help_text,
        _(
          "<p>Additionally, you can create an archive image of the directory using tar. To create an \nimage, specify the name and the location in the respective fields.</p>\n"
        )
      )

      Wizard.SetContents(
        @title,
        @contents,
        @help_text,
        Convert.to_boolean(WFM.Args(0)),
        Convert.to_boolean(WFM.Args(1))
      )


      @ret = nil

      while true
        @image = Convert.to_boolean(UI.QueryWidget(Id(:makeimage), :Value))
        if @image
          UI.ChangeWidget(Id(:imagename), :Enabled, true)
          UI.ChangeWidget(Id(:imagedir), :Enabled, true)
          UI.ChangeWidget(Id(:open_dir), :Enabled, true)
        else
          UI.ChangeWidget(Id(:imagename), :Enabled, false)
          UI.ChangeWidget(Id(:imagedir), :Enabled, false)
          UI.ChangeWidget(Id(:open_dir), :Enabled, false)
        end
        @autoyast = Convert.to_boolean(
          UI.QueryWidget(Id(:use_autoyast), :Value)
        )
        UI.ChangeWidget(Id(:autoyast), :Enabled, @autoyast)
        UI.ChangeWidget(Id(:open_profile), :Enabled, @autoyast)
        @ret = Wizard.UserInput

        break if @ret == :abort && Popup.ConfirmAbort(:painless)

        break if @ret == :cancel || @ret == :back
        if @ret == :open_dir
          # directory selection header
          @dir = UI.AskForExistingDirectory(
            DirInstall.image_dir,
            _("Select Directory")
          )
          if @dir != nil
            UI.ChangeWidget(Id(:imagedir), :Value, Convert.to_string(@dir))
          end
          next
        end
        if @ret == :open_profile
          @current_file = Convert.to_string(
            UI.QueryWidget(Id(:autoyast), :Value)
          )
          @file = UI.AskForExistingFile(
            @current_file,
            "*.xml",
            _("Select AutoYaST Profile")
          )
          if @file != nil
            UI.ChangeWidget(Id(:autoyast), :Value, Convert.to_string(@file))
          end
          next
        end
        if @ret == :next
          @target = Convert.to_string(UI.QueryWidget(Id(:target), :Value))
          @runme_at_boot = Convert.to_boolean(
            UI.QueryWidget(Id(:suseconfig), :Value)
          )
          DirInstall.makeimage = Convert.to_boolean(
            UI.QueryWidget(Id(:makeimage), :Value)
          )
          DirInstall.image_name = Convert.to_string(
            UI.QueryWidget(Id(:imagename), :Value)
          )
          DirInstall.image_dir = Convert.to_string(
            UI.QueryWidget(Id(:imagedir), :Value)
          )
          @w_autoyast = Convert.to_string(UI.QueryWidget(Id(:autoyast), :Value))

          if Convert.to_boolean(UI.QueryWidget(Id(:use_autoyast), :Value)) &&
              (DirInstall.autoyast_software != @w_autoyast ||
                !DirInstall.use_autoyast_software)
            if Profile.ReadXML(@w_autoyast)
              # reset the current selection, start from scratch
              Pkg.PkgReset

              @settings = Ops.get_map(Profile.current, "software", {})
              Builtins.y2milestone("Read software data: %1", @settings)

              @patterns = Ops.get_list(@settings, "patterns", [])
              Builtins.y2milestone("Installing patterns: %1", @patterns)
              Builtins.foreach(@patterns) do |pat|
                Pkg.ResolvableInstall(pat, :pattern)
              end

              @post_patterns = Ops.get_list(@settings, "post-patterns", [])
              Builtins.y2milestone("Installing post-patterns: %1", @patterns)
              Builtins.foreach(@post_patterns) do |pat|
                Pkg.ResolvableInstall(pat, :pattern)
              end

              @packages = Ops.get_list(@settings, "packages", [])

              @notFound = ""
              Builtins.foreach(@packages) do |pack|
                if !Pkg.IsAvailable(pack)
                  @notFound = Ops.add(Ops.add(@notFound, pack), "\n")
                end
              end

              if Ops.greater_than(Builtins.size(@notFound), 0)
                Builtins.y2error("packages not found: %1", @notFound)
                # warning text when selecting packages. %1 is a list of package names
                Report.LongError(
                  Builtins.sformat(
                    _(
                      "These packages could not be found in the software repositories:\n%1"
                    ),
                    @notFound
                  )
                )
              end

              @kernel = Ops.get_string(@settings, "kernel", "")

              if @kernel != nil && @kernel != ""
                Builtins.y2milestone("Adding kernel package: %1", @kernel)
                @packages = Builtins.add(@packages, @kernel)
              end

              @post_packages = Ops.get_list(@settings, "post-packages", [])
              if Ops.greater_than(Builtins.size(@post_packages), 0)
                Builtins.y2milestone(
                  "Merging post-packages: %1",
                  @post_packages
                )
                @packages = Convert.convert(
                  Builtins.merge(@packages, @post_packages),
                  :from => "list",
                  :to   => "list <string>"
                )
              end

              Builtins.y2milestone("Selecting packages: %1", @packages)
              Pkg.DoProvide(@packages)

              @taboo_packages = Ops.get_list(@settings, "remove-packages", [])
              if Ops.greater_than(Builtins.size(@taboo_packages), 0)
                Builtins.y2milestone("Taboo packages: %1", @taboo_packages)
                Builtins.foreach(@taboo_packages) { |tp| Pkg.PkgTaboo(tp) }
              end

              Builtins.y2internal(
                "products after import: %1",
                Pkg.ResolvableProperties("", :product, "")
              )
            else
              Report.Error(_("Failed to read the AutoYaST profile."))
              next
            end
          end
          DirInstall.use_autoyast_software = Convert.to_boolean(
            UI.QueryWidget(Id(:use_autoyast), :Value)
          )
          DirInstall.autoyast_software = @w_autoyast

          if @target == "" || @target == "/"
            # popup message
            Popup.Message(_("Specify a root directory. This does not mean /"))
            next
          end

          DirInstall.SetTarget(@target)
          Installation.destdir = @target
          DirInstall.runme_at_boot = @runme_at_boot

          break
        end
      end

      Wizard.CloseDialog

      deep_copy(@ret)
    end
  end
end

Yast::DirinstallOptionsClient.new.main
