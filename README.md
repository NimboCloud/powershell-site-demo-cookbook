powershell-site-demo Cookbook
===================
This cookbook demos how Chef can dynamically build a static site using local machine information. This can be very helpful for creating status pages for internal and external applications.

In this demo, the site is installing Azure PowerShell plugins and running a command to dump all of the images to a CSV file. While this could be done via an API call, the purpose of this cookbook is to demo create a static site with local information.

[Demo Site](http://chef-azure-site.cloudapp.net/)

Requirements
------------
 - Chocolatey
 - Windows


Attributes
----------
 - ["powershell-site-demo"]["short_sitename"]: Used for the path and the app pool name. No spaces please
 - ["powershell-site-demo"]["sitename"]: Printed on the site... why not?
 - ["powershell-site-demo"]["publishing_file"]: Must be located in files/default/azure-sub (make sure not to commit this file!)

Usage
-----
#### azure-site::default

Just include `powershell-site-demo` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[powershell-site-demo]"
  ]
}
```

License and Authors
-------------------
Authors:

 - Michael Lapidakis
