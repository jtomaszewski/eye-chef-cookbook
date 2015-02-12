#
# Cookbook Name:: eye 
# Resource:: service
#
# Copyright 2013, Holger Amann <holger@fehu.org>
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

actions :start, :stop, :enable, :disable, :load, :restart, :reload
default_action :start

attribute :service_name, :name_attribute => true
attribute :enabled, :default => false
attribute :running, :default => false
attribute :variables, :kind_of => Hash
attribute :supports, :default => { :restart => true, :status => true }
attribute :user_srv, :kind_of => [TrueClass, FalseClass], :default => false
attribute :user_srv_uid, :kind_of => [NilClass, String], :default => nil
attribute :user_srv_gid, :kind_of => [NilClass, String], :default => nil
attribute :init_script_prefix, :kind_of => String, :default => ''
attribute :user_srv_home, :kind_of => String, :default => nil

attribute :config_path, :kind_of => [NilClass, String], :default => nil
attribute :bin, :kind_of => [NilClass, String], :default => nil
