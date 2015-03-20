require 'spec_helper'

describe 'apache_c2c::userdirinstance' do
  let(:title) { 'foo' }
  let(:pre_condition) { 'include ::apache_c2c' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          :concat_basedir => '/tmp',
        })
      end

      let(:root) do
        case facts[:osfamily]
        when 'Debian'
          '/var/www'
        else
          '/var/www/vhosts'
        end
      end

      describe 'using example vhost' do
        let(:params) { {
          :vhost => 'www.example.com',
        } }

        case facts[:osfamily]
        when 'Debian'
          it { should contain_file("#{root}/www.example.com/conf/userdir.conf").with( {
            :ensure  => 'present',
            :source  => 'puppet:///modules/apache_c2c/userdir.conf',
            :seltype => nil,
          } ) }
        else
          it { should contain_file("#{root}/www.example.com/conf/userdir.conf").with( {
            :ensure  => 'present',
            :source  => 'puppet:///modules/apache_c2c/userdir.conf',
            :seltype => 'httpd_config_t',
          } ) }
        end
      end

      describe 'ensuring absence' do
        let(:params) { {
          :ensure => 'absent',
          :vhost  => 'www.example.com',
        } }

        it { should contain_file("#{root}/www.example.com/conf/userdir.conf").with_ensure('absent') }
      end
    end
  end
end
