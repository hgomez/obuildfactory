%define base_url        %{BASE_URL}

Name:           obuildfactory-centos-repo
Version:        1.0.0
Release:        1
Summary:        OBuildFactory repo

Group:          System Environment/Base
License:        GPLv2
URL:            %{base_url}
Source0:        RPM-GPG-KEY-obuildfactory
Source1:        obuildfactory-centos.repo
Source2:        gpl-2.0.txt
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch:      noarch

%description 
This package installs 'RPM-GPG-KEY-obuildfactory' and obuildfactory.repo files 

%prep
%setup -c -T

%build

%install
rm -rf %{buildroot}

# gpg
install -Dpm 0644 %{SOURCE0} %{buildroot}%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-obuildfactory

# yum
install -Dpm 0644 %{SOURCE1} %{buildroot}%{_sysconfdir}/yum.repos.d/obuildfactory.repo
sed -i "s|@@BASE_URL@@|%{base_url}|g" %{buildroot}%{_sysconfdir}/yum.repos.d/obuildfactory.repo

# GPLv2
install -Dpm 0644 %{SOURCE2} %{buildroot}%{_prefix}/share/doc/obuildfactory/gpl-2.0.txt

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_sysconfdir}/pki/rpm-gpg/*
%config %{_sysconfdir}/yum.repos.d/*
%dir %{_prefix}/share/doc/obuildfactory
%{_prefix}/share/doc/obuildfactory/*

%changelog
* Sun Sep 09 2011 Henri Gomez <henri.gomez@gmail.com> 1.0.0-1
- Initial Import