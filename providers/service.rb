# Provider:: service
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

require 'chef/mixin/shell_out'
require 'chef/mixin/language'

include Chef::Mixin::ShellOut

action :enable do
  template_suffix = case node['platform_family']
                    when 'implement_me' then node['platform_family']
                    else 'lsb'
                    end
  cache_service_user = service_user
  cache_service_group = service_group
  template "#{node['eye']['init_dir']}/#{new_resource.init_script_prefix}#{new_resource.service_name}" do
    source "eye_init.#{template_suffix}.erb"
    cookbook "eye"
    owner cache_service_user
    group cache_service_group
    mode "0755"
    variables(
              :service_name => new_resource.service_name,
              :eye_bin => eye_bin,
              :config_file => config_file,
              :user => cache_service_user
              )
    only_if { ::File.exists?(config_file) }
  end

  unless @current_resource.enabled
    service "#{new_resource.init_script_prefix}#{new_resource.service_name}" do
      action [ :enable ]
    end

    new_resource.updated_by_last_action(true)
  end
end

action :load do
  unless @current_resource.running
    run_command(load_command)
    new_resource.updated_by_last_action(true)
  end
end

action :reload do
  run_command(stop_command) if @current_resource.running
  run_command(load_command)
  new_resource.updated_by_last_action(true)
end

action :start do
  unless @current_resource.running
    run_command(start_command)
    new_resource.updated_by_last_action(true)
  end
end

action :disable do
  if @current_resource.enabled
    if user_conf_dir
      file config_file do
        action :delete
      end
    end

    link "#{node['eye']['init_dir']}/#{new_resource.service_name}" do
      action :delete
    end

    new_resource.updated_by_last_action(true)
  end
end

action :stop do
  if @current_resource.running
    run_command(stop_command)
    new_resource.updated_by_last_action(true)
  end
end

action :restart do
  if @current_resource.running
    run_command(restart_command)
    new_resource.updated_by_last_action(true)
  end
end

def load_current_resource
  @current_resource = Chef::Resource::EyeService.new(new_resource.name)
  @current_resource.service_name(new_resource.service_name)

  determine_current_status!

  @current_resource
end

protected

def status_command
  "#{eye_bin} info #{new_resource.service_name}"
end

def load_command
  "#{eye_bin} load #{config_file}"
end

def load_eye
  "#{eye_bin} load"
end

def start_command
  "#{eye_bin} start #{new_resource.service_name}"
end

def stop_command
  "#{eye_bin} stop #{new_resource.service_name}"
end

def restart_command
  "#{eye_bin} restart #{new_resource.service_name}"
end

def run_command(command, opts = {})
  home = user_home(service_user)
  env_variables = { 'HOME' => home }
  cmd = shell_out(command, :user => service_user, :group => service_group, :env => env_variables)
  cmd.error! unless opts[:dont_raise]
  cmd
end

def determine_current_status!
  service_running?
  service_enabled?
end

def service_running?
  begin
    # get sure eye master process is running
    run_command(load_eye)

    if run_command(status_command, { :dont_raise => true }).exitstatus > 0
      @current_resource.running false
    else
      @current_resource.running true
    end
  rescue Mixlib::ShellOut::ShellCommandFailed, SystemCallError
    @current_resource.running false
    nil
  end
end

def service_enabled?
  if ::File.exists?(config_file) &&
      ::File.exists?("#{node['eye']['init_dir']}/#{new_resource.init_script_prefix}#{new_resource.service_name}")
    @current_resource.enabled true
  else
    @current_resource.enabled false
  end
end

def user_home(user)
  home = if new_resource.user_srv_home.nil?
           node['etc']['passwd'][user]['dir']
         else
           home = new_resource.user_srv_home
         end
  home
end

def service_user
  new_resource.user_srv ? new_resource.user_srv_uid : node['eye']['user']
end

def service_group
  new_resource.user_srv ? new_resource.user_srv_gid : node['eye']['group']
end

def user_conf_dir
  ::File.join(node['eye']['conf_dir'], service_user) if node['eye']['conf_dir']
end

def user_log_dir
  ::File.join(node['eye']['log_dir'], service_user) if node['eye']['log_dir']
end

def config_file
  new_resource.config_path ||
    ::File.join(user_conf_dir, "#{new_resource.service_name}.eye")
end

def eye_bin
  new_resource.bin || node['eye']['bin']
end
