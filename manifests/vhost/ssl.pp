# == Definition: apache::vhost::ssl
#
# Creates an SSL enabled virtualhost.
#
# As it calls apache::vhost, most of the parameters are the same. A few
# additional parameters are used to configure the SSL specific stuff.
#
# An "ssl" subdirectory will be created in the virtualhost's directory. By
# default, 3 files will be created in this subdirectory using the
# generate-ssl-cert.sh script: $name.key (the private key), $name.crt (the
# self-signed certificate) and $name.csr (the certificate signing request). An
# additional file, ssleay.cnf, is used as a template by generate-ssl-cert.sh.
#
# Parameters:
# - *$name*: the name of the virtualhost. Will be used as the CN in the
#   generated ssl certificate.
# - *$ensure*: see apache::vhost
# - *$config_file*: see apache::vhost
# - *$config_content*: see apache::vhost
# - *$htdocs_source*: see apache::vhost
# - *$conf_source*: see apache::vhost
# - *$cgi_source*: see apache::vhost
# - *$private_source*: see apache::vhost
# - *$readme*: see apache::vhost
# - *$docroot*: see apache::vhost
# - *$cgibin*: see apache::vhost
# - *$user*: see apache::vhost
# - *$admin*: see apache::vhost
# - *$group*: see apache::vhost
# - *$mode*: see apache::vhost
# - *$aliases*: see apache::vhost. The generated SSL certificate will have this
#   list as DNS subjectAltName entries.
# - *$ip_address*: the ip address defined in the <VirtualHost> directive.
#   Defaults to "*".
# - *$cert*: optional source URL of the certificate (see examples below), if the
#   default self-signed generated one doesn't suit. This the certificate passed
#   to the SSLCertificateFile directive.
# - *$certkey*: optional source URL of the private key, if the default generated
#   one doesn't suit. This the private key passed to the SSLCertificateKeyFile
#   directive.
# - *$cacert*: optional source URL of the CA certificate, if the defaults
#   bundled with your distribution don't suit. This the certificate passed to
#   the SSLCACertificateFile directive.
# - *$cacrl*: optional source URL of the CA certificate revocation list.
#   This is the file passed to the SSLCARevocationFile directive.
# - *$certchain*: optional source URL of the CA certificate chain, if needed.
#   This the certificate passed to the SSLCertificateChainFile directive.
# - *$verifyclient*: set the Certificate verification level for the Client
#   Authentication. Must be one of 'none', 'optional', 'require' or
#   'optional_no_ca'.
# - *$options*: Configure various SSL engine run-time options.
# - *$days*: validity of the key/cert generated by generate-ssl-cert.sh.
#   Defaults to 10 years.
# - *$publish_csr*: if set to "true", the CSR will be copied in
#   htdocs/$name.csr.
#   If set to a path, the CSR will be copied into the specified file. Defaults
#   to "false", which means don't copy the CSR anywhere.
# - *$sslonly*: if set to "true", only the https virtualhost will be configured.
#   Defaults to "true", which means there is a redirection from non-SSL port to
#   SSL
# - *ports*: array specifying the ports on which the non-SSL vhost will be
#   reachable. Defaults to "*:80".
# - *sslports*: array specifying the ports on which the SSL vhost will be
#   reachable. Defaults to "*:443".
# - *accesslog_format*: format string for access logs. Defaults to "combined".
# - *$sslcert_commonname*: set a custom CN field in your SSL certificate. Note that
#   the CN field must match the FQDN of your virtualhost to avoid "certificate
#   name mismatch" errors in the users browsers. Defaults to $name.
# - *$sslcert_country*: set the countryName field in your SSL certificate. Defaults
#   to '??'.
# - *$sslcert_state*: set the stateOrProvinceName field in your SSL certificate.
# - *$sslcert_locality*: set the localityName field in your SSL certificate.
# - *$sslcert_organization*: set the organizationName field in your SSL certificate.
#    Defaults to 'undefined organisation'.
# - *$sslcert_unit*: set the organizationalUnitName field in your SSL certificate.
# - *$sslcert_email*: set the emailAddress field in your SSL certificate.
#
# Requires:
# - Class["apache-ssl"]
#
# Example usage:
#
#   $sslcert_country="US"
#   $sslcert_state="CA"
#   $sslcert_locality="San Francisco"
#   $sslcert_organization="Snake Oil, Ltd."
#
#   include apache_c2c::ssl
#
#   apache_c2c::vhost::ssl { "foo.example.com":
#     ensure => present,
#     ip_address => "10.0.0.2",
#     publish_csr => "/home/webmaster/foo.example.com.csr",
#     days="30",
#   }
#
#   # go to https://bar.example.com/bar.example.com.csr to retrieve the CSR.
#   apache_c2c::vhost::ssl { "bar.example.com":
#     ensure => present,
#     ip_address => "10.0.0.3",
#     cert => "puppet:///modules/exampleproject/ssl-certs/bar.example.com.crt",
#     certchain => "puppet:///modules/exampleproject/ssl-certs/quovadis.chain.crt",
#     publish_csr => true,
#     sslonly => true,
#   }

define apache_c2c::vhost::ssl (
  $ensure=present,
  $config_file='',
  $config_content=false,
  $htdocs_source=false,
  $conf_source=false,
  $cgi_source=false,
  $private_source=false,
  $readme=false,
  $docroot=false,
  $cgibin=true,
  $user='',
  $admin=undef,
  $group='',
  $mode=2570,
  $aliases=[],
  $ip_address='*',
  $cert=false,
  $certkey=false,
  $cacert=false,
  $cacrl=false,
  $certchain=false,
  $verifyclient=undef,
  $options=[],
  $days='3650',
  $publish_csr=false,
  $sslonly=true,
  $ports=['*:80'],
  $sslports=['*:443'],
  $accesslog_format='combined',
  $sslcert_commonname=$name,
  $sslcert_country='??',
  $sslcert_state=undef,
  $sslcert_locality=undef,
  $sslcert_organization='undefined organisation',
  $sslcert_unit=undef,
  $sslcert_email=undef,
) {

  # Validate parameters
  if ($verifyclient != undef) {
    validate_re(
      $verifyclient,
      '(none|optional|require|optional_no_ca)',
      'verifyclient must be one of none, optional, require or optional_no_ca'
    )
  }
  validate_array($options)

  include apache_c2c::params

  $wwwuser = $user ? {
    ''      => $apache_c2c::params::user,
    default => $user,
  }

  $wwwgroup = $group ? {
    ''      => $apache_c2c::params::group,
    default => $group,
  }

  # used in ERB templates
  $wwwroot = $apache_c2c::root
  validate_absolute_path($wwwroot)

  $documentroot = $docroot ? {
    false   => "${wwwroot}/${name}/htdocs",
    default => $docroot,
  }

  $cgipath = $cgibin ? {
    true    => "${wwwroot}/${name}/cgi-bin/",
    false   => false,
    default => $cgibin,
  }

  # define variable names used in vhost-ssl.erb template
  $certfile      = "${wwwroot}/${name}/ssl/${name}.crt"
  $certkeyfile   = "${wwwroot}/${name}/ssl/${name}.key"
  $csrfile       = "${wwwroot}/${name}/ssl/${name}.csr"

  # By default, use CA certificate list shipped with the distribution.
  if $cacert != false {
    $cacertfile = "${wwwroot}/${name}/ssl/cacert.crt"
  } else {
    $cacertfile = $::operatingsystem ? {
      /RedHat|CentOS/ => '/etc/pki/tls/certs/ca-bundle.crt',
      /Debian|Ubuntu/ => '/etc/ssl/certs/ca-certificates.crt',
    }
  }

  # If a revocation file is provided
  if $cacrl != false {
    $cacrlfile = "${wwwroot}/${name}/ssl/cacert.crl"
  }

  if $certchain != false {
    $certchainfile = "${wwwroot}/${name}/ssl/certchain.crt"
  }

  # call parent definition to actually do the virtualhost setup.
  $_sslonly = $sslonly ? {
    false   => template(
      "${module_name}/vhost.erb", "${module_name}/vhost-ssl.erb"),
    default => template(
      "${module_name}/vhost-redirect-ssl.erb","${module_name}/vhost-ssl.erb"),
  }
  $_config_content = $config_content ? {
    false   => $_sslonly,
    default => $config_content,
  }
  apache_c2c::vhost {$name:
    ensure           => $ensure,
    config_file      => $config_file,
    config_content   => $_config_content,
    aliases          => $aliases,
    htdocs_source    => $htdocs_source,
    conf_source      => $conf_source,
    cgi_source       => $cgi_source,
    private_source   => $private_source,
    readme           => $readme,
    docroot          => $docroot,
    user             => $wwwuser,
    admin            => $admin,
    group            => $wwwgroup,
    mode             => $mode,
    ports            => $ports,
    accesslog_format => $accesslog_format,
  }

  if $ensure == 'present' {
    file { "${wwwroot}/${name}/ssl":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      seltype => 'cert_t',
      require => [File["${wwwroot}/${name}"]],
    }

    # template file used to generate SSL key, cert and csr.
    file { "${wwwroot}/${name}/ssl/ssleay.cnf":
      ensure  => present,
      owner   => 'root',
      mode    => '0640',
      content => template("${module_name}/ssleay.cnf.erb"),
      require => File["${wwwroot}/${name}/ssl"],
    }

    # The certificate and the private key will be generated only if $name.crt
    # or $name.key are absent from the "ssl/" subdir.
    # The CSR will be re-generated each time this resource is triggered.
    exec { "generate-ssl-cert-${name}":
      command => "/usr/local/sbin/generate-ssl-cert.sh ${name} ${wwwroot}/${name}/ssl/ssleay.cnf ${wwwroot}/${name}/ssl/ ${days}",
      creates => $csrfile,
      notify  => Exec['apache-graceful'],
      require => [
        File["${wwwroot}/${name}/ssl/ssleay.cnf"],
        File['/usr/local/sbin/generate-ssl-cert.sh'],
      ],
    }

    # The virtualhost's certificate.
    # Manage content only if $cert is set, else use the certificate generated
    # by generate-ssl-cert.sh
    $certfile_source = $cert ? {
      false   => undef,
      default => $cert,
    }
    file { $certfile:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      source  => $certfile_source,
      seltype => 'cert_t',
      notify  => Exec['apache-graceful'],
      require => [
        File["${wwwroot}/${name}/ssl"],
        Exec["generate-ssl-cert-${name}"],
        ],
    }

    # The virtualhost's private key.
    # Manage content only if $certkey is set, else use the key generated by
    # generate-ssl-cert.sh
    $certkeyfile_source = $certkey ? {
      false   => undef,
      default => $certkey,
    }
    file { $certkeyfile:
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      source  => $certkeyfile_source,
      seltype => 'cert_t',
      notify  => Exec['apache-graceful'],
      require => [
        File["${wwwroot}/${name}/ssl"],
        Exec["generate-ssl-cert-${name}"],
        ],
    }

    if $cacert != false {
      # The certificate from your certification authority. Defaults to the
      # certificate bundle shipped with your distribution.
      file { $cacertfile:
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        source  => $cacert,
        seltype => 'cert_t',
        notify  => Exec['apache-graceful'],
        require => File["${wwwroot}/${name}/ssl"],
      }
    }

    if $cacrl != false {
      # certificate revocation file
      file { $cacrlfile:
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        source  => $cacrl,
        seltype => 'cert_t',
        notify  => Exec['apache-graceful'],
        require => File["${wwwroot}/${name}/ssl"],
      }
    }

    if $certchain != false {

      # The certificate chain file from your certification authority's. They
      # should inform you if you need one.
      file { $certchainfile:
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        source  => $certchain,
        seltype => 'cert_t',
        notify  => Exec['apache-graceful'],
        require => File["${wwwroot}/${name}/ssl"],
      }
    }

    # put a copy of the CSR in htdocs, or another location if $publish_csr
    # specifies so.
    $public_csr_ensure = $publish_csr ? {
      false   => 'absent',
      default => 'present',
    }
    $public_csr_path = $publish_csr ? {
      true    => "${wwwroot}/${name}/htdocs/${name}.csr",
      false   => "${wwwroot}/${name}/htdocs/${name}.csr",
      default => $publish_csr,
    }
    $public_csr_source = $publish_csr ? {
      false   => undef,
      default => "file://${csrfile}",
    }
    file { "public CSR file for ${name}":
      ensure  => $public_csr_ensure,
      path    => $public_csr_path,
      source  => $public_csr_source,
      mode    => '0640',
      seltype => 'httpd_sys_content_t',
      require => Exec["generate-ssl-cert-${name}"],
    }

  }
}
