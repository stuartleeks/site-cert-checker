@description('Base name to use for the deployment')
param baseName string = 'site-cert-checker'
@description('A list of pipe (|) separated hostnames to check')
param sitesToCheck string = 'example.com|another.example.com'
@description('The number of days prior to expiry to allow before warning')
param expiryGraceDays int = 7
@description('The email address to send expiry notifications to')
param emailAddress string

var location = resourceGroup().location

// storage accounts must be between 3 and 24 characters in length and use numbers and lower-case letters only
var storageAccountName = '${replace(substring(baseName, 0, 10), '-', '')}${uniqueString(resourceGroup().id)}'
var functionPlanName = '${baseName}${uniqueString(resourceGroup().id)}'
var appInsightsName = '${baseName}${uniqueString(resourceGroup().id)}'
var functionAppName = baseName
var logicAppName = '${baseName}${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${functionAppName}': 'Resource'
  }
}

// This connector will require authorisation once deployed (access in portal and follow the warning banner on the resource)
// To automate from local machine, try https://github.com/logicappsio/LogicAppConnectionAuth
resource logicAppO365Connection 'Microsoft.Web/connections@2016-06-01' = {
  name: '${logicAppName}-office365'
  location: location
  properties: {
    displayName: emailAddress
    api: {
      name: 'office365'
      brandColor: '#0078D4'
      type: 'Microsoft.Web/locations/managedApis'
      displayName: 'Office 365 Outlook'
      description: 'Microsoft Office 365 is a cloud-based service that is designed to help meet your organization\'s needs for robust security, reliability, and user productivity.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1521/1.0.1521.2572/office365/icon.png'
      id: '/subscriptions/67ce421f-bd68-463d-85ff-e89394ca5ce6/providers/Microsoft.Web/locations/${location}/managedApis/office365'
    }
  }
}

// Load the workflow from JSON file
// This can be exported
// NOTE: parameters/connections need to be manually updated below
var workflow = json(replace(loadTextContent('workflow.json'), 'test@example.com', emailAddress))

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: workflow.definition
    parameters: {
      // NOTE - need to keep this updated with the workflow
      '$connections': {
        'value': {
          'office365': {
            'connectionId': logicAppO365Connection.id
            'connectionName': 'office365'
            'id': '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
          }
        }
      }
    }
  }
  dependsOn:[
    logicAppO365Connection
  ]
}

resource functionPlan 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: functionPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}
resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: functionPlan.id
    clientAffinityEnabled: true
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: 'https://github.com/stuartleeks/site-cert-checker/releases/latest/download/functions.zip'
        }
        {
          name: 'SitesToCheck'
          value: sitesToCheck
        }
        {
          name: 'ExpiryGraceDays'
          value: string(expiryGraceDays)
        }
        {
          name: 'ExpiryPostUrl'
          value: listCallbackURL('${resourceId('Microsoft.Logic/workflows', logicAppName)}/triggers/manual', '2016-06-01').value
        }
      ]
    }
  }

  dependsOn: [
    appInsights
    functionPlan
    storageAccount
    logicApp
  ]
}
