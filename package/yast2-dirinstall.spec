#
# spec file for package yast2-dirinstall
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           yast2-dirinstall
Version:        3.0.1
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0

# Installation::dirinstall_target
# Wizard::SetDesktopTitleAndIcon
Requires:	yast2 >= 2.21.22
# Package-split
Requires:	yast2-packager >= 2.16.3

Requires:	yast2 yast2-country yast2-mouse yast2-runlevel autoyast2-installation

BuildRequires:	yast2 >= 2.16.7
BuildRequires:	perl-XML-Writer update-desktop-files yast2-testsuite
BuildRequires:  yast2-devtools >= 3.0.6
# xmllint - for dirinstall.xml validation
BuildRequires:	libxml2
# control.rng - validation schema
BuildRequires:  yast2-installation >= 2.17.44

Provides:	/usr/share/YaST2/clients/dirinstall.ycp

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Installation into Directory

%description
This package contains scripts for installing a new system into separate
directory.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/dirinstall
%{yast_yncludedir}/dirinstall/*
%{yast_clientdir}/*.rb
%{yast_moduledir}/*
%{yast_desktopdir}/*.desktop
%dir /usr/share/YaST2/control
/usr/share/YaST2/control/*.xml
%doc %{yast_docdir}

