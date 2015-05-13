name             'baragon'
maintainer       'EverTrue'
maintainer_email 'devops@evertrue.com'
license          'Apache 2.0'
description      'Installs/Configures baragon'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.2.0'
issues_url       'https://github.com/evertrue/singularity-cookbook/issues'
source_url       'https://github.com/evertrue/singularity-cookbook'

supports 'ubuntu', '= 14.04'

depends 'java'
depends 'git'
depends 'logrotate'
depends 'maven'
depends 'logrotate'
