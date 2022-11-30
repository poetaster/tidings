# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.32
# 

Name:       harbour-tidings

# >> macros
# << macros

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    RSS / Atom / Podcasts / Feed Reader
Version:    1.3.0
Release:    1
Group:      Qt/Qt
License:    GPLv2
Source0:    %{name}-%{version}.tar.bz2
Requires:   qt5-plugin-imageformat-gif
Requires:   qt5-plugin-imageformat-ico
Requires:   sailfishsilica-qt5
Requires:   qtmozembed-qt5
Requires:   sailfish-components-webview-qt5
Requires:   qt5-qtdeclarative-import-xmllistmodel

%if "%{?vendor}" == "chum"
BuildRequires:  qt5-qttools-linguist
%endif
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Concurrent)
BuildRequires:  pkgconfig(Qt5Xml)
BuildRequires:  pkgconfig(sailfishapp)
BuildRequires:  pkgconfig(qt5embedwidget)
BuildRequires:  desktop-file-utils

%description
Tidings is a news feed and podcast aggregator. Always be up to date with the latest news of what matters to you on your mobile device.

%if "%{?vendor}" == "chum"
PackageName: Tidings
Type: desktop-application
Categories:
 - News
 - Network
DeveloperName: Mark Washeim
Custom:
 - Repo: https://github.com/poetaster/tidings
Icon: https://raw.githubusercontent.com/poetaster/tidings/master/icons/172x172/harbour-tidings.png
Screenshots:
 - https://raw.githubusercontent.com/poetaster/tidings/master/screen-1.jpg
 - https://raw.githubusercontent.com/poetaster/tidings/master/screen-2.jpg
 - https://raw.githubusercontent.com/poetaster/tidings/master/screen-3.jpg
Url:
  Donation: https://www.paypal.me/poetasterFOSS
%endif

%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qtc_qmake5 

%qtc_make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/%{name}/qml
%{_datadir}/icons/hicolor/*/apps/%{name}.png
# >> files
# << files
