Summary: ElasticSearch SIMP Puppet Module
Name: pupmod-simp-elasticsearch
Version: 2.0.0
Release: 0
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: hiera >= 1.2.1
Requires: pupmod-electrical-elasticsearch >= 0.1.2-3
Requires: pupmod-apache >= 4.0-13
Requires: pupmod-common >= 4.1.0-5
Requires: pupmod-iptables >= 4.0.0-0
Requires: puppet >= 3.0.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-simp-elasticsearch-test

Prefix: /etc/puppet/environments/simp/modules

%description
This puppet module uses the ElasticSearch module provided by Richard Pijnenburg
(electrical: https://github.com/electrical) and moulds it into the SIMP
framework with some reasonable defaults.

The target with this is a LogStash environment but it should be flexible enough
to suit most purposes.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/elasticsearch

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/elasticsearch
done

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files
%defattr(0640,root,puppet,0750)
%{prefix}/elasticsearch/manifests/simp.pp
%{prefix}/elasticsearch/manifests/simp
%{prefix}/elasticsearch/templates/simp
%{prefix}/elasticsearch/lib/puppet/parser/functions/es_iptables_format.rb

%post
#!/bin/sh

%postun
# Post uninstall stuff

%changelog
* Tue Feb 24 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-0
- Updated to move into the new default 'simp' environment.

* Fri Dec 19 2014 Ralph Wright <rwight@onyxpoint.com> - 1.0.0-8
- Correct the permissions on the ES templates directory.

* Thu Dec 18 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-7
- Removed our pre-set defaults for the ES tuning. Real world testing
  indicates that the pre-built defaults perform better.

* Tue Dec 16 2014 Kendall Moore <kmoore@keywcorp.com> - 1.0.0-6
- Updated the elasticsearch Apache template in accordance with the latest Apache upgrades.

* Fri Oct 17 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-5
- CVE-2014-3566: Updated protocols to mitigate POODLE.

* Fri Sep 05 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-4
- Updated to supporrt elasticsearch 1.3, which requires Java 1.7.
- Added support for installing the es2unix utilities.

* Mon Jul 21 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-3
- Updated to use /var/elasticsearch for SIMP>=5

* Fri May 16 2014 Kendall Moore <kmoore@keywcorp.com> - 1.0.0-2
- Coverted Apache cipher set to array and updated the elasticsearch template.

* Tue May 06 2014 Trevur Vaughan <tvaughan@onyxpoint.com> - 1.0.0-1
- Made things more Hiera friendly.
- Updated the global ldap* calls to use hiera settings.

* Thu Mar 13 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-0
- Removed the es_mem option and added the service_settings hash in its
  place to allow for maximum flexibility.
- Moved the insanely large default hashes over to
  elasticsearch::simp::default and updated the documentation
  accordingly.

* Mon Dec 09 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.2.0-0
- Update to fix some typos related to installing java.

* Fri Oct 04 2013 Nick Markowski <nmarkowski@keywcorp.com> - 0.1.2-2
- Updated template to reference instance variables with @

* Tue Sep 24 2013 Kendall Moore <kmoore@keywcorp.com> - 0.1.2-1
- Require puppet 3.X and puppet-server 3.X because of an upgrade to use
  hiera instead of extdata.

* Mon Aug 12 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.1.2-0
- First cut at SIMP integration of the ElasticSearch module from 'electrical'
  https://github.com/electrical/puppet-elasticsearch.
