# Docker support for building OpenJDK for different OSes

## How does docker help?

Docker allows you from most any distribution of Linux to run build
steps within another distribution of Linux. So from your Ubuntu box
you can build openjdk for all CentOS releases, other Ubuntu releases,
and so on.

## Build steps

For this proof of concept to see if folks are interested there are
only a limited number of rules for a limited number of
distributions. However, in theory, one jenkins host with docker could
probably the majority if not all packages for all linux distributions.


```
$ make centos7-openjdk8
```

  or

```
$ make ubuntu15-openjdk8
```

These would would leave RPMs or DEBs under
build/centos7-openjdk8/binaries or build/ubuntu15-openjdk8/binaries
respectively.

## Bootstrapping OpenJDK9

The rules for OpenJDK9 require that you build OpenJDK8 first. So, for
example:

```
$ make centos7-openjdk8
$ make centos7-openjdk9
```

  or

```
$ make centos7-openjdk8 centos7-openjdk9
```
