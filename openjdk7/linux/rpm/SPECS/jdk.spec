# Avoid jar repack (brp-java-repack-jars)
#%define __jar_repack 0

# Avoid CentOS 5/6 extras processes on contents (especially brp-java-repack-jars)
%define __os_install_post %{nil}

%ifos darwin
%define __portsed sed -i "" -e
%else
%define __portsed sed -i
%endif

%if 0%{?jdk_type:1}
%define jdk_nameext    -fastdebug
%define jdk_commentext with fast debug
%else
%define jdk_nameext    %{nil}
%define jdk_commentext %{nil}
%endif

#
# OpenJDK 1.7.0 packaging (32/64bits)
#

# disable debug info
%define debug_package %{nil}

# get ride of *** ERROR: No build ID note found ... in CentOS
# %undefine _missing_build_ids_terminate_build

#
# JDK Definition
#
%define origin          openjdk
%define javaver         1.7.0

Summary: %{origin} JDK %{javaver} Environment

# Adjust RPM version (- is not allowed, lowercase strings)
%define rpm_rel_version %(version_rel=`echo %{jvm_version} | sed "s/-/./g" | tr "[:upper:]" "[:lower:]"`; echo "$version_rel")

#
# jvm_version is provided via --define externally, to rpm convention via rpm_rel_version
#
Version: %{javaver}.%{rpm_rel_version}
Release: 1%{?dist}

#
# Force _jvmdir to be into /opt/obuildfactory where all jvms will be stored
#
%define _jvmdir	/opt/obuildfactory

#
# http://www.rpm.org/api/4.4.2.2/conditionalbuilds.html
#
%if %{cum_jdk}
 # Name contain jdk + Version + Origin + Version + Architecture (32/64) -> QA mode
Name:    jdk-%{javaver}-%{origin}-%{jvm_version}-%{jdk_model}%{jdk_nameext}
%define jdkdir          %{_jvmdir}/jdk-%{javaver}-%{origin}-%{jdk_model}%{jdk_nameext}-%{jvm_version}
%else
# Name contain jdk + Version + Origin + Architecture (32/64) -> Ops mode
Name:    jdk-%{javaver}-%{origin}-%{jdk_model}%{jdk_nameext}
%define jdkdir          %{_jvmdir}/jdk-%{javaver}-%{origin}-%{jdk_model}%{jdk_nameext}
%endif

# java-1.5.0-ibm from jpackage.org set Epoch to 1 for unknown reasons,
# and this change was brought into RHEL-4.  java-1.5.0-ibm packages
# also included the epoch in their virtual provides.  This created a
# situation where in-the-wild java-1.5.0-ibm packages provided "java =
# 1:1.5.0".  In RPM terms, "1.6.0 < 1:1.5.0" since 1.6.0 is
# interpreted as 0:1.6.0.  So the "java >= 1.6.0" requirement would be
# satisfied by the 1:1.5.0 packages.  Thus we need to set the epoch in
# JDK package >= 1.6.0 to 1, and packages referring to JDK virtual
# provides >= 1.6.0 must specify the epoch, "java >= 1:1.6.0".
Epoch:   1

Group:   Development/Languages
Packager: obuildfactory

# Standard JPackage base provides.
Provides: jre-%{javaver}-%{origin} = %{epoch}:%{version}-%{release}
Provides: jre-%{origin} = %{epoch}:%{version}-%{release}
Provides: jre-%{javaver} = %{epoch}:%{version}-%{release}
Provides: java-%{javaver} = %{epoch}:%{version}-%{release}
Provides: jre = %{javaver}
Provides: java-%{origin} = %{epoch}:%{version}-%{release}
Provides: java = %{epoch}:%{javaver}
# Standard JPackage extensions provides.
Provides: jndi = %{epoch}:%{version}
Provides: jndi-ldap = %{epoch}:%{version}
Provides: jndi-cos = %{epoch}:%{version}
Provides: jndi-rmi = %{epoch}:%{version}
Provides: jndi-dns = %{epoch}:%{version}
Provides: jaas = %{epoch}:%{version}
Provides: jsse = %{epoch}:%{version}
Provides: jce = %{epoch}:%{version}
Provides: jdbc-stdext = 3.0
Provides: java-sasl = %{epoch}:%{version}
Provides: java-fonts = %{epoch}:%{version}

License:  GPL-2.0
URL:      http://openjdk.java.net

SOURCE0: j2sdk-image.tar.bz2
BuildRoot: %{_tmppath}/build-%{name}-%{version}-%{release}

%if 0%{?fedora} || 0%{?rhel} || 0%{?centos}

# 32bits JVM on 64bits OS requires 32bits libs
%ifarch x86_64
%if %{jdk_model} == i686
Requires: alsa-lib.i686
Requires: dbus-glib.i686
Requires: glibc.i686
Requires: libXext.i686
Requires: libXi.i686
Requires: libXt.i686
Requires: libXtst.i686
%endif
%endif

Requires: alsa-lib
Requires: dbus-glib
Requires: glibc
Requires: libXext
Requires: libXi
Requires: libXt
Requires: libXtst

%endif

%description
This package contains the JDK from %{origin} %{javaver} %{jdk_commentext}

%package db
Summary:        JavaDB files from %{origin} %{javaver}
Group:          Development/Languages
Requires:       %{name} = %{epoch}:%{version}-%{release}

%description db
This package contains JavaDB files from %{origin} %{javaver}

%package demo
Summary:        Demos files from %{origin} %{javaver}
Group:          Development/Languages
Requires:       %{name} = %{epoch}:%{version}-%{release}

%description demo
This package contains contains files from %{origin} %{javaver} 

%package sample
Summary:        Samples files from %{origin} %{javaver}
Group:          Development/Languages
Requires:       %{name} = %{epoch}:%{version}-%{release}

%description sample
This package contains samples files from %{origin} %{javaver}

%package src
Summary:        Source Bundle from %{origin} %{javaver}
Group:          Development/Languages
Requires:       %{name} = %{epoch}:%{version}-%{release}

%description src
This package contains Source Bundle files from %{origin} %{javaver}

%prep
%setup -n j2sdk-image

%build

%install
# Prep the install location.
rm -rf %{buildroot}
mkdir -p %{buildroot}%{jdkdir}

mv * %{buildroot}%{jdkdir}

# Remove .diz files
find %{buildroot}%{jdkdir} -type f -name "*.diz" -delete 

# exclude db, demo, sample related files from main contents
find %{buildroot}%{jdkdir} -type d \
  | grep -v %{jdkdir}/demo \
  | grep -v %{jdkdir}/sample \
  | sed 's|'%{buildroot}'|%dir |' \
  > %{name}.files

find %{buildroot}%{jdkdir} -type f -o -type l \
  | grep -v %{jdkdir}/db \
  | grep -v jdb \
  | grep -v man/man1 \
  | grep -v man/ja \
  | grep -v man/jp \
  | grep -v %{jdkdir}/demo \
  | grep -v %{jdkdir}/sample \
  | grep -v src.zip \
  | sed 's|'%{buildroot}'| |' \
  >> %{name}.files

%if !%{cum_jdk}
mkdir -p %{buildroot}/%{_sysconfdir}/sysconfig
cat > %{buildroot}/%{_sysconfdir}/sysconfig/%{name} << EOF1
JAVA_HOME=%{jdkdir}
EOF1
echo "/etc/sysconfig/%{name}" >> %{name}.files
%endif

%clean
rm -rf %{buildroot}

%files -f %{name}.files
%defattr(-,root,root)
%doc %{jdkdir}/man

%files db
%defattr(-,root,root)
%{jdkdir}/bin/jdb
%{jdkdir}/man/man1/jdb.1
%{jdkdir}/man/ja_JP.UTF-8/man1/jdb.1

%files demo
%defattr(-,root,root)
%{jdkdir}/demo

%files sample
%defattr(-,root,root)
%{jdkdir}/sample

%files src
%defattr(-,root,root)
%{jdkdir}/src.zip

%changelog
* Sat Sep 1 2012 henri.gomez@gmail.com 1.7.0.7u7-1
- Initial package
