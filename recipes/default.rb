#
# Cookbook Name:: powershell-site-demo
# Recipe:: default
#
# Copyright 2014, Nimbo
#
# All rights reserved - Do Not Redistribute
#

#Install Chocolatey repo
include_recipe 'chocolatey'
require 'csv'

#Install the Azure Plugin for powershell using Chocolatey
chocolatey 'WindowsAzurePowershell'

#Create a directory for the publishing file and copy it over.
remote_directory "#{ENV['SYSTEMDRIVE']}\\AzurePub\\" do
  source "azure-sub"
  rights :read, "Administrators"
  action :create
end

#Add the publishing file to PowerShell Azure only if one does not exist
powershell_script "install the publishing file" do
  code "Import-AzurePublishSettingsFile #{ENV['SYSTEMDRIVE']}\\AzurePub\\#{node["powershell-site-demo"]["publishing_file"]}"
  not_if "((Get-AzureSubscription).Environment -ccontains 'AzureCloud')"
end

#Install IIS on the server
powershell_script "Install IIS" do
  code "add-windowsfeature Web-Server"
  action :run
end

#Autostart IIS on reboot
service "w3svc" do
  action [ :enable, :start ]
end

#Disable the default site
powershell_script "disable default site" do
  code 'get-website "Default Web Site*" | where {$_.state -ne "Stopped"} | Stop-Website'
end

#Define the directory for the new site
site_dir = "#{ENV['SYSTEMDRIVE']}\\inetpub\\wwwroot\\#{node["powershell-site-demo"]["short_sitename"]}"

directory site_dir

#Create a new app pool for the site.
powershell_script "create app ppol for #{node["powershell-site-demo"]["short_sitename"]}" do
  code "New-WebAppPool #{node["powershell-site-demo"]["short_sitename"]}"
  not_if "C:\\Windows\\System32\\inetsrv\\appcmd.exe list appPool #{node["powershell-site-demo"]["short_sitename"]}"
end

#Create a new website
powershell_script "new website for #{node["powershell-site-demo"]["short_sitename"]}" do
  code <<-EOH
    Import-Module WebAdministration
    if(-not(test-path IIS:\\Sites\\#{node["powershell-site-demo"]["short_sitename"]})){
      New-WebSite -name #{node["powershell-site-demo"]["short_sitename"]} -Port 80 -PhysicalPath #{site_dir} -ApplicationPool #{node["powershell-site-demo"]["short_sitename"]}
    }
  EOH
end

#Copy over the assets (css and js)
remote_directory "#{site_dir}\\" do
  source "powershell-site-demo"
  rights :read, "Everyone"
  action :create
end

#Export all of the azure images
powershell_script "Dump the azure images to a csv" do
  code <<-EOH
    Get-AzureVMImage | Export-Csv #{Chef::Config[:file_cache_path]}\\AzureImages.csv
  EOH
end

#Turn that CSV into an array
arImages = Array.new
arImages = CSV.read("#{Chef::Config[:file_cache_path]}\\AzureImages.csv")

#Create the main page using the template
template "#{site_dir}\\Default.htm" do
  source "Default.htm.erb"
  rights :read, "Everyone"
  variables(
    :short_site_name => node["powershell-site-demo"]["short_sitename"],
    :site_name => node["powershell-site-demo"]["sitename"],
    :arImages => arImages
  )
  notifies :restart, "service[w3svc]"
end
