# encoding: UTF-8
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module ACME
  module Extensions
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    # Returns a list of all containers from the endpoint.
    #
    # @param [Boolean] all
    #   When true will show all containers (started and stopped), when false
    #   only running containers are listed.
    #
    # @return [Array]
    #
    def running(all = true)
      Docker::Container.all(all: true)
    end

    # Request a Container by ID or name.
    #
    # @param [String] name
    #   The name of the container to get.
    #
    # @return [Docker::Container]
    #
    def get(name)
      Docker::Container.get(name)
    end

    # Check to see if a given container exists, it is considered to exists if
    # it has a state of restarting, running, paused, or exited.
    #
    # @param [String] name
    #   The name of the container to get.
    #
    # @return [Boolean]
    #
    def exists?(name)
      running.map { |r| r.info['Names'].include?("/#{name}") }.any?
    end

    def join_ip
      @ip ||= get('consul').json['NetworkSettings']['IPAddress']
    rescue Docker::Error::NotFoundError
      nil
    end

    # TODO -- this is silly
    def ok;      'OK'.green;       end
    def warning; 'Warning'.yellow; end
    def fail;    'Fail'.red;       end

    def chef_user_exists?(user)
      cmd = ['bash', '-c', 'chef-server-ctl user-list']
      get('chef').exec(cmd).flatten[0].split.include?(user)
    end

    def create_chef_user(user, full_name, email, passwd, org)
      pemfile = File.join(BASEDIR, '.chef', "#{org}-#{user}.pem")
      if chef_user_exists?(user)
        puts "The user #{user} already exists on the Chef server."
        @client_key = open(pemfile)
      else
        cmd  = ['chef-server-ctl', 'user-create']
        cmd << [user, "'#{full_name}'", email, passwd]
        cmd  = ['bash', '-c', cmd.join(' ')]
        @client_key = get('chef').exec(cmd).flatten[0]
        pemfile = File.join('.chef', "#{org}-#{user}.pem")
        open(pemfile, File::CREAT|File::TRUNC|File::RDWR, 0644) do |file|
          file << @client_key
        end
      end
    end

    def chef_org_exists?(org)
      cmd = ['bash', '-c', 'chef-server-ctl org-list']
      get('chef').exec(cmd).flatten[0].split.include?(org)
    end

    def create_chef_org(org, long_name, user)
      pemfile = File.join(BASEDIR, '.chef', "#{org}-validator.pem")
      if chef_org_exists?(org)
        puts "The org #{org} already exists on the Chef server."
        @validation_key = open(pemfile)
      else
        cmd  = ['chef-server-ctl', 'org-create']
        cmd << [org, "'#{long_name}'", '--association', user]
        cmd  = ['bash', '-c', cmd.join(' ')]
        @validation_key = get('chef').exec(cmd).flatten[0]
        open(pemfile, File::CREAT|File::TRUNC|File::RDWR, 0644) do |file|
          file << @validation_key
        end
      end
    end

    def render_data_bag(org)
      cwd      = File.expand_path(File.dirname(__FILE__))
      data_bag = File.join(cwd, '../templates', 'data_bag.json.erb')
      template = ERB.new(File.read(data_bag))
      result   = template.result(binding)
      dest     = File.join(BASEDIR, 'data_bag', 'chef_org', "#{org}.json")
      open(dest, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f << result }
    end

    def render_knife
      cwd      = File.expand_path(File.dirname(__FILE__))
      data_bag = File.join(cwd, '../templates', 'knife.rb.erb')
      template = ERB.new(File.read(data_bag))
      result   = template.result(binding)
      dest     = File.join(BASEDIR, '.chef', 'knife.rb')
      open(dest, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f << result }
    end

    def docker_kernel
      puts "\nSetting Docker host SHMMAX and SHMALL kernel paramaters:"
      host, user = `docker-machine ip`.strip, 'docker'
      keys = [File.join(ENV['DOCKER_CERT_PATH'], 'id_rsa')]
      ['sudo sysctl -w kernel.shmmax=17179869184',
       'sudo sysctl -w kernel.shmall=4194304'
      ].each do |cmd|
        resp = Net::SSH.start(host, user, keys: keys) { |ssh| ssh.exec!(cmd) }
        printf "%1s %22s %-12s\n", '', "[#{resp.strip.yellow}]", ''
      end
      puts
    end
  end
end
