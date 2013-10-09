define apache::userdirinstance(
  $vhost,
  $ensure = present,
) {

  $wwwroot = $apache::root
  validate_absolute_path($wwwroot)

  $seltype = $::operatingsystem ? {
    'RedHat' => 'httpd_config_t',
    'CentOS' => 'httpd_config_t',
    default  => undef,
  }
  file { "${wwwroot}/${vhost}/conf/userdir.conf":
    ensure  => $ensure,
    source  => "puppet:///modules/${module_name}/userdir.conf",
    seltype => $seltype,
    notify  => Exec['apache-graceful'],
  }
}
