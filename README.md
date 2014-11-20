orchard-continuous-integration-demo
===================================

Continuous integration proof of concept using Orchard CMS, Git, GitHub, and MS Azure Websites.

Copy and paste the following two files into your repository root. Then push.

- `.deployment`
- `deploy.orchard.cmd`

We create the basic templates for these files by running `azure site deploymentscript --aspWAP src\Orchard.Web\Orchard.csproj -s src\Orchard.sln`. Then we modify them to use Orchard's `build\precompiled` functionality.
