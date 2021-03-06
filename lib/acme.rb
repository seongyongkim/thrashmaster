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

require 'erb'
require 'rake'
require 'docker'
require 'hoodie'
require 'net/ssh'

require_relative 'acme/utils'
require_relative 'acme/extensions'
require_relative 'acme/container_dsl'
require_relative 'acme/container'
require_relative 'acme/prerequisites'

module ACME
  Docker.url = ENV['DOCKER_HOST']
  Docker.options = {
    client_cert: File.join(ENV['DOCKER_CERT_PATH'], 'cert.pem'),
    client_key:  File.join(ENV['DOCKER_CERT_PATH'], 'key.pem'),
    ssl_ca_file: File.join(ENV['DOCKER_CERT_PATH'], 'ca.pem'),
    scheme: 'https'
  }

  # Hook called when an object is extended with ACME.
  #
  # @param [Object] object
  #
  # @return [undefined]
  #
  # @api private
  def self.extended(object)
    super
    object.instance_eval do
      extend ACME::Utils
      extend ACME::Extensions
    end
  end
  private_class_method :extended
end
