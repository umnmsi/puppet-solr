# == Class: solr
#
# Installs solr using the embedded version of jetty.
# Configures solr and starts the service.
#
# Note, if you are using Centos, you will most likely need to configure
# your firewall rules like so
#     add IP Tables
#     /sbin/iptables -I INPUT 1 -p tcp --dport 8983 -j ACCEPT
#     /sbin/service iptables save
#     service iptables restart
#
# === Parameters
#
# [*version*]
#   The version to install.
#   Default: 6.1.0
#
# [*url*]
#   The url of the source repository for apache solr.
#   Default: 'http://mirrors.gigenet.com/apache/lucene/solr',
#
# [*timeout*]
#   The timeout used for downloading the solr package.
#   Default: 120 seconds.
#
# [*manage_user*]
#   Whether to manage the solr user or not
#   Default: true
#
# [*solr_user*]
#   Run Solr as this user ID.
#   Note, creates this user.
#   Default: solr
#
# [*solr_host*]
#   Listen to connections from this network host
#   Use 0.0.0.0 as solr_host to accept all connections.
#   Default: 127.0.0.1
#
# [*solr_port*]
#   The network port used by Jetty
#   Default Port: 8983
#
# [*solr_heap*]
#   The heap size used by jetty.
#   Default: 512m
#
# [*solr_downloads*]
#   Contains the solr tarballs and extracted dirs.
#
# [*install_dir*]
#   The install directory (`-i`) parameter passed to the solr installer.
#   Default: '/opt'
#
# [*install_dir_mg*]
#   Sets if this module should manage the install directory.
#   True if this module should manage and false otherwise.
#   Default: false
#
# [*solr_home*]
#   The home directory for solr.
#   Default: "${install_dir}/solr" (/opt/solr)
#
# [*var_dir*]
#   The var directory for solr.
#   Default: '/var/solr'
#
# [*solr_logs*]
#   The directory for the solr logs.
#   Default: "/var/log/solr"
#
# [*java_home*]
#   The directory that contains the jvm.
#   Default: (os specific)
#     * Debian/Ubuntu: '/usr/lib/jvm/java-8-openjdk-amd64/jre'
#     * CentOS/RHEL: '/usr/lib/jvm/jre-1.8.0'
#
# [*solr_environment*]
#   ARRAY - Bash style environment variables passed at the end of the solr
#   server environment.
#   Default: []
#
# [*cores*]
#   An array of hashes that define a core which will be created with the
#   create_resources function.
#   See type solr::core for details.
#   Default: {}
#
# [*zk_hosts*]
#   For configuring ZooKeeper ensemble.
#   Default: '[]'
#
# [*log4j_maxfilesize*]
#   Maximum allowed log file size (in bytes) before rolling over.
#   Suffixes "KB", "MB" and "GB" are allowed.
#   Default: 4MB
#
# [*log4j_maxbackupindex*]
#   Maximum number of log backup files to keep.
#   Default: 9
#
# [*log4j_rootlogger_loglevel*]
#   The loglevel to set for log4j.
#   Use the defined enum.  Valid options
#  'ALL', 'DEBUG', 'ERROR', 'FATAL', 'INFO', 'OFF', 'TRACE', 'TRACE_INT','WARN'
#   Default: 'INFO'
#
# [*schema_name*]
#   The Solr cores' schema name. This should be set to `schema.xml` if using
#   the classic schema.xml method. If using a managed schema, set this to
#   Solr's "managedSchemaResourceName" setting, typically 'manage-schema'.
#   Refer to Solr's documentation for `core.properties` for details.
#   Default: varies by version:
#     Solr >= 5.6.0 will use 'manage-schema'
#     Solr < 5.6.0 will default to 'schema.xml'
#
# === Variables
#
# [*solr_core_home*]
#   The directory that contains cores.
#
# [*basic_dir*]
#   The directory to the basic configuration example core.
#
# [*solr_lib_dir*]
#   The directory to install shared libraries for use by solr.
#
# === Examples
#
# include solr
#
# === Copyright
#
# GPL-3.0+
#
class solr (
  $version                    = $solr::params::version,
  $url                        = $solr::params::url,
  $timeout                    = $solr::params::timeout,
  $manage_user                = $solr::params::manage_user,
  $solr_user                  = $solr::params::solr_user,
  $solr_host                  = $solr::params::solr_host,
  $solr_port                  = $solr::params::solr_port,
  $solr_heap                  = $solr::params::solr_heap,
  $solr_downloads             = $solr::params::solr_downloads,
  $install_dir                = $solr::params::install_dir,
  $install_dir_mg             = $solr::params::install_dir_mg,
  $var_dir                    = $solr::params::var_dir,
  $solr_logs                  = $solr::params::solr_logs,
  $solr_home                  = $solr::params::solr_home,
  $java_home                  = $solr::params::java_home,
  $solr_environment           = [],
  $cores                      = {},
  $required_packages          = $solr::params::required_packages,
  $zk_hosts                   = $solr::params::zk_hosts,
  $log4j_maxfilesize          = $solr::params::log4j_maxfilesize,
  $log4j_maxbackupindex       = $solr::params::log4j_maxbackupindex,
  Variant[
    Enum[
      'ALL',
      'DEBUG',
      'ERROR',
      'FATAL',
      'INFO',
      'OFF',
      'TRACE',
      'TRACE_INT',
      'WARN'
    ],
    String
  ] $log4j_rootlogger_loglevel  = $solr::params::log4j_rootlogger_loglevel,
  $schema_name                 = undef,
) inherits ::solr::params{

  ## === Variables === ##
  $solr_env       = $solr::params::solr_env
  $solr_core_home = $solr_home
  $solr_pid_dir   = $var_dir
  $solr_bin       = "${install_dir}/solr/bin"
  $solr_server    = "${install_dir}/solr/server"
  $basic_dir      = "${solr_server}/solr/configsets/basic_configs/conf"
  $solr_lib_dir   = "${solr_server}/solr-webapp/webapp/WEB-INF/lib"

  # If no value for `schema_name` is provided, use a sensible default for this
  # version of Solr.
  case $schema_name {
    undef: {
      # I have confirmed that managed-schema doesn't work in 5.5.3
      # So I am pushing to version 5.6.0.
      if versioncmp($solr::version, '5.6.0') >= 0 {
        $schema_filename = 'managed-schema'
      } else {
        $schema_filename = 'schema.xml'
      }
    }
    default: {
      $schema_filename = $schema_name
    }
  }

  anchor{'solr::begin': }

  class{'solr::install':
    require => Anchor['solr::begin'],
  }

  class{'solr::config':
    require => Class['solr::install'],
  }

  class{'solr::service':
    subscribe => Class['solr::config'],
  }

  if $cores =~ Hash {
    create_resources(::solr::core, $cores)
  }

  anchor{'solr::end':
    require => Class['solr::service'],
  }
}
