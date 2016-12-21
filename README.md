# OBuildFactory

[![Join the chat at https://gitter.im/hgomez/obuildfactory](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/hgomez/obuildfactory?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

![OBuildFactory Logo](https://raw.github.com/hgomez/obuildfactory/master/OBuildFactory-Logo.png)

This GitHub project  provides build scripts for OpenJDK 7, 8, 8+Lambda, 8+Jigsaw.

These scripts add goodies like :

* ROOT CA generation, update and inclusion
* FreeType build and embedding on platform where minimal requirements are not met.
* Native packages support, aka Linux RPMs up to trusted Yum repository population.
* OSX DMG for easy install via drag&drop.

 
You could use these scripts from a Jenkins Powered environment to setup a Continuous Integration chain or standalone for one shot builds.

Initialy planned for Linux, this project also include Mac OSX scripts from [openjdk-osx-build](http://code.google.com/p/openjdk-osx-build/) 

# Documentation

[Wiki](https://github.com/hgomez/obuildfactory/wiki)

## Linux

Build and packages are tested on CentOS 5, 6, Fedora 18, openSUSE 12.2 and Ubuntu 12.10 weekly on my home package factory (motorized by Jenkins). Binary packages will be uploaded to Bintray really soon on a weekly basis.

[How to build and package OpenJDK 7 on Linux](https://github.com/hgomez/obuildfactory/wiki/How-to-build-and-package-OpenJDK-7-on-Linux)

[How to build and package OpenJDK 8 on Linux](https://github.com/hgomez/obuildfactory/wiki/How-to-build-and-package-OpenJDK-8-on-Linux)

[How to build and package OpenJDK 9 on Linux](https://github.com/hgomez/obuildfactory/wiki/How-to-build-and-package-OpenJDK-9-on-Linux)

### Yum repositories

Thanks to JFrog Bintray, OpenJDKs for Linux are available for major Linux distributions in yum repositories, install repositories like :

#### CentOS 5 32bits

    curl -L https://bintray.com/hgomez/obuildfactory-centos5-i386/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/

#### CentOS 5 64bits

    curl -L https://bintray.com/hgomez/obuildfactory-centos5-x86-64/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/

#### CentOS 6 32bits

    curl -L https://bintray.com/hgomez/obuildfactory-centos6-i386/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/

#### CentOS 6 64bits

    curl -L https://bintray.com/hgomez/obuildfactory-centos6-x86-64/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/

#### Fedora 17/18 32bits

    curl -L https://bintray.com/hgomez/obuildfactory-fedora18-i386/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/

#### Fedora 17/18 64bits
    
    curl -L https://bintray.com/hgomez/obuildfactory-fedora18-x86-64/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/

#### Fedora 19 32bits

    curl -L https://bintray.com/hgomez/obuildfactory-fedora19-i386/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/

#### Fedora 19 64bits
    
    curl -L https://bintray.com/hgomez/obuildfactory-fedora19-x86-64/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/

#### Fedora 20 32bits

    curl -L https://bintray.com/hgomez/obuildfactory-fedora20-i386/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/


#### Fedora 20 64bits
    
    curl -L https://bintray.com/hgomez/obuildfactory-fedora20-x86-64/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/yum.repos.d/


#### openSUSE 12.x 32bits

    curl -L https://bintray.com/hgomez/obuildfactory-opensuse122-i386/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/zypp/repos.d/

#### openSUSE 12.x 64bits

    curl -L  https://bintray.com/hgomez/obuildfactory-opensuse122-x86-64/rpm -o bintray-hgomez-obuildfactory.repo
    sudo mv bintray-hgomez-obuildfactory.repo /etc/zypp/repos.d/

Then you could install rpm like this :

    # install openjdk8 lambda on CentOS/Fedora 32bits
    sudo yum install jdk-1.8.0-lambda-openjdk-i686
    # install openjdk8 on CentOS/Fedora 64bits
    sudo yum install jdk-1.8.0-openjdk-x86_64
    # install openjdk7 on SLES/openSUSE 64bits
    sudo zypper install jdk-1.7.0-openjdk-x86_64
    
And then update then with yum/zypper :

    # update obuildfactory package on CentOS/Fedora
    sudo yum update
    # update obuildfactory package on SLES/openSUSE
    sudo zypper update

## OSX

There is some wiki pages who detailed how to build, but there is no guaranty about success.
I don't have OSX machines anymore so I cannot help anymore on this OS

[Building and packaging OpenJDK7 for OSX](https://github.com/hgomez/obuildfactory/wiki/Building-and-Packaging-OpenJDK7-for-OSX)

[Building and packaging OpenJDK8 for OSX](https://github.com/hgomez/obuildfactory/wiki/Building-and-Packaging-OpenJDK8-for-OSX)

[Building and packaging OpenJDK9 for OSX](https://github.com/hgomez/obuildfactory/wiki/Building-and-Packaging-OpenJDK9-for-OSX)


## Licence

These scripts are provided under Apache Software Licence 2.0.
