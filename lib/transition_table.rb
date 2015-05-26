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

class TransitionTable
  class TransitionError < RuntimeError
    def initialize(state, input)
      super
        "No transition from state #{state.inspect} for input #{input.inspect}"
    end
  end
  include Enumerable

  def initialize(transitions)
    @transitions = transitions
  end

  def call(state, input)
    @transitions.fetch([state, input])
  rescue KeyError
    raise TransitionError.new(state, input)
  end

  def each
    @transitions.each_pair {|key, value| yield *key, *value }
  end
end
