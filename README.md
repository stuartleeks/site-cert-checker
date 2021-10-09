# Site-Cert-Checker

Site cert(ificate) checker is a project for checking for upcoming certificate expiry for web sites.

It deploys a timer-triggered Azure Function that checks the certificates for the configured list of sites. If any issues are found, it calls an Azure Logic App which sends an email notification via an Office 365 account.

## Getting Started

To deploy site-cert-checker as-is, you need:
- an Azure subscription
- an Office 365 account 

To deploy, use the deployment button below: 

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fstuartleeks%2Fsite-cert-checker%2Fmain%2Fdeploy%2Fout%2Fmain.json?1)

Once the deployment has completed, navigate to the resource group you deployed to and open the API Connection resource. This should display a warning banner - click on this and then click the Authorize button to enable the Logic App to connect to your Office 365 account.

### Configuration options


| Option                  | Description                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------- |
| Base Name               | A prefix for the created Azure resources (default: site-cert-checker)               |
| Sites To Check          | A pipe-separated list of sites to check (e.g. my-site.example.com\|www.example.com) |
| Expiry Grace Days       | The number of days prior to expiry to allow before warning (default: 7)             |
| Email Address To Notify | The email address to send emails to when there are cert issues                      |


