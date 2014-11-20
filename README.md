orchard-continuous-integration-demo
===================================

Continuous integration proof of concept using Orchard CMS, Git, GitHub, and MS Azure Websites.

These are the key files to make it happen:

- `.deployment`
- `deploy.orchard.cmd`
- `deploy.cmd` is the out-of-the-box file that we modify. Compare it to `deploy.orchard.cmd` if you're interested.

We create the basic templates for these files by running `azure site deploymentscript --aspWAP src\Orchard.Web\Orchard.csproj -s src\Orchard.sln`. Then we modify them to use Orchard's `build\precompiled` functionality.
