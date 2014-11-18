orchard-continuous-integration-demo
===================================

Continuous integration proof of concept using Orchard CMS, Git, GitHub, and MS Azure Websites.

These are the key files to make it happen:

- `.deployment`
- `deploy.cmd`

The `deploy.cmd` contains almost all of the logic. We create the basic template for this file by running `azure site deploymentscript --aspWAP src\Orchard.Web\Orchard.csproj -s src\Orchard.sln`. Then we modify that file to use Orchard's `build\precompiled` instead of the default temporary artifacts.
