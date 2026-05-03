# Agentholics - Retail Management Platform

A comprehensive Salesforce-based retail management solution that enables field teams to manage store visits, analyze retail locations, and leverage AI-powered insights for retail operations.

## Overview

Agentholics is an enterprise retail management platform built on Salesforce that combines:
- **AI-Powered Retail Agent**: Intelligent assistant for retail operations and visit management
- **Location Analytics**: Advanced store location analysis and recommendations
- **Visit Management**: Comprehensive field visit scheduling, tracking, and documentation
- **Retail Dashboard**: Real-time insights and metrics for retail operations
- **Data Integration**: AWS S3 connectivity for external data sources

## Key Features

### 🤖 Agentforce Retail Agent
- Natural language interaction for retail operations
- Automated visit scheduling and rescheduling
- Knowledge article integration
- Visit note analysis with AI

### 📊 Retail Dashboard
- Real-time store performance metrics
- Visit tracking and analytics
- Location-based insights
- Interactive data visualizations

### 📍 Location Intelligence
- Store location analysis and scoring
- Competitive analysis integration
- Geographic coordinate conversion
- Best location recommendations

### 📅 Visit Management
- Create, schedule, and cancel visits
- Retrieve contact visit history
- Automated visit note processing
- Platform event-driven updates

### 🔄 Automation & Flows
- Retail store analysis workflows
- Location average calculations
- Route-to-work automation
- OTP verification for secure operations

## Architecture

### Lightning Web Components
- `retailDashboard`: Main dashboard component for retail metrics and insights

### Apex Classes
**Controllers:**
- `RetailDashboardController`: Dashboard data provider
- Various community and authentication controllers

**Actions (Invocable):**
- `CreateVisitAction`: Schedule new store visits
- `CancelVisitAction`: Cancel scheduled visits
- `RescheduleVisitAction`: Modify visit schedules
- `GetContactVisitsAction`: Retrieve visit history
- `getRetailStoresAction`: Fetch retail store data

**Services:**
- `StoreLocationAnalysis`: Analyze and score store locations
- `VisitNoteService`: Process and analyze visit notes
- `LocationTriggerHandler`: Handle location data changes
- `NoteProcessorQueueable`: Asynchronous note processing

### Triggers
- `EventRiseTrigger`: Platform event handler for real-time updates

### Flows & Process Automation
**Core Flows:**
- `Retail_Store_Analysis`: Comprehensive store performance analysis
- `analyze_location`: Location viability assessment
- `Analyze_Store_Location`: Store site evaluation
- `suggestBestLocations`: AI-powered location recommendations
- `Route_To_Work`: Field service routing
- `GetAllVisits`: Visit data aggregation

**Integration Flows:**
- OTP verification and security
- Discovery call assessment
- Platform event processing

### Data Integration
- **AWS S3 Connector**: External data source integration
- **Data Stream Definitions**: Competitor data processing
- **Platform Events**: Real-time event-driven architecture

## Project Structure

```
force-app/main/default/
├── classes/              # Apex business logic
├── lwc/                  # Lightning Web Components
├── triggers/             # Database triggers
├── flows/                # Flow automation definitions
├── bots/                 # Agentforce bot configurations
├── objects/              # Custom object definitions
├── genAiPromptTemplates/ # AI prompt configurations
├── mktDataSources/       # Marketing data connectors
└── staticresources/      # Static assets
```

## Prerequisites

- Salesforce CLI (sf CLI)
- Node.js (LTS version)
- Visual Studio Code with Salesforce Extensions
- Git
- Access to a Salesforce org (scratch org, sandbox, or production)

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd Agentholics
```

### 2. Authenticate to Your Org
```bash
sf org login web --alias agentholics-org
```

### 3. Deploy Metadata
```bash
sf project deploy start --source-path force-app/main/default
```

### 4. Assign Permission Sets
```bash
sf org assign permset --name <permission-set-name>
```

### 5. Configure the Retail Agent
- Navigate to Setup → Bots
- Activate the Retail Agent bot
- Configure agent actions and topics

### 6. Set Up AWS S3 Connection (Optional)
- Configure AWS credentials in Named Credentials
- Test the data source connection

## Development

### Create a Scratch Org
```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias agentholics-scratch --set-default
```

### Push Source to Scratch Org
```bash
sf project deploy start
```

### Run Tests
```bash
sf apex run test --code-coverage --result-format human
```

### Pull Changes
```bash
sf project retrieve start --source-path force-app/main/default
```

## Key Components

### Retail Dashboard
Lightning Web Component providing real-time insights:
- Store performance metrics
- Visit completion rates
- Location analytics
- Interactive charts and visualizations

### Agentforce Retail Agent
AI-powered conversational agent supporting:
- Visit scheduling ("Schedule a visit to Store X")
- Visit management ("Cancel my visit tomorrow")
- Store queries ("Show me all visits for this contact")
- Knowledge access ("How do I complete a store audit?")

### Location Analysis System
Sophisticated location scoring considering:
- Demographic data
- Competitor proximity
- Traffic patterns
- Historical performance

## API Integration

### Invocable Actions
All actions are available for Flow, Process Builder, and API calls:
- `CreateVisitAction.createVisits()`
- `CancelVisitAction.cancelVisits()`
- `RescheduleVisitAction.rescheduleVisits()`
- `GetContactVisitsAction.getContactVisits()`

### Platform Events
Subscribe to real-time events for:
- Visit status changes
- Location updates
- Analysis completion

## Testing

Run all tests:
```bash
sf apex run test --test-level RunLocalTests --code-coverage --result-format human
```

Run specific test class:
```bash
sf apex run test --tests <TestClassName> --result-format human
```

## Configuration

### Custom Settings & Metadata
Review and configure:
- Bot configurations in `bots/Retail_Agent/`
- Flow definitions in `flows/`
- AI prompt templates in `genAiPromptTemplates/`
- Data source settings in `mktDataSources/`

### Security
- Review permission sets for appropriate access
- Configure field-level security
- Set up data sharing rules
- Enable platform encryption if required

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and ensure coverage
4. Submit pull request with description

## Troubleshooting

### Common Issues

**Bot Not Responding:**
- Verify bot is activated
- Check agent action configurations
- Review Platform Event subscriptions

**Location Analysis Failing:**
- Confirm coordinate data is valid
- Check Flow activation status
- Verify custom object permissions

**Dashboard Not Loading:**
- Check RetailDashboardController test coverage
- Verify LWC static resources
- Review browser console for errors

## Resources

- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Lightning Web Components Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Agentforce Developer Guide](https://developer.salesforce.com/docs/einstein/genai/guide/agentforce-overview.html)
- [Salesforce Flows Documentation](https://help.salesforce.com/s/articleView?id=sf.flow.htm)

## License

[Specify your license here]

## Support

For issues and questions:
- Create an issue in the repository
- Contact the development team
- Review documentation in the wiki

---

**Version:** 1.0  
**Last Updated:** May 2026  
**Maintained By:** Agentholics Development Team