**Stripe Payment Gateway Integration with Salesforce**

🎯** Overview**
This project provides a production-ready integration between Salesforce and Stripe, allowing sales teams to generate and send payment links to customers directly from Opportunity records. The solution handles product data synchronization, payment link generation, and automated customer notifications.
Why This Project?

Streamlined Payment Process: Generate payment links with a single click
Automated Communication: Automatic email delivery to customers
Real-time Integration: Seamless data flow between Salesforce and Stripe
Secure Configuration: API credentials stored in Custom Metadata
User-Friendly: Lightning Web Component with intuitive interface

✨ **Features**

✅ One-Click Payment Links: Generate Stripe payment links from Opportunity products

✅ Dynamic Product Sync: Automatically sync OpportunityLineItems to Stripe

✅ Automated Emails: Send payment links to customers via email

✅ Multi-Currency Support: Handle different currencies (USD, EUR, etc.)

✅ Real-time Pricing: Calculate total prices dynamically

✅ Secure Credentials: API keys stored in Custom Metadata Types

✅ Error Handling: Comprehensive error handling and user feedback

✅ Test Mode Support: Full testing capability in Stripe test mode

✅ Responsive UI: Mobile-friendly Lightning Web Component


📦 **Prerequisites**
Before installing this integration, ensure you have:

Salesforce Developer Edition, Enterprise, or Unlimited Edition
Salesforce API enabled
Admin access to Salesforce org
Stripe account (Test mode is sufficient for development)
VS Code with Salesforce Extensions installed (for deployment)

🚀 **Installation**
Step 1: Clone the Repository

bashgit clone https://github.com/yourusername/salesforce-stripe-integration.git

cd salesforce-stripe-integration

Step 2: Deploy to Salesforce

Option A: Using SFDX CLI
bash# Authenticate to your org
sfdx auth:web:login -a YourOrgAlias

# Deploy the source
sfdx force:source:deploy -p force-app/main/default -u YourOrgAlias
Option B: Using VS Code

Open the project in VS Code
Right-click on force-app folder
Select SFDX: Deploy Source to Org

Step 3: **File Structure**

After deployment, verify these components are deployed:

force-app/

└── main/

    └── default/
    
        ├── classes/
        
        │   ├── stripePaymentHelper.cls
        
        │   └── stripePaymentHelper.cls-meta.xml
        
        ├── lwc/
        │   └── stripePaymentCmp/

        │       ├── stripePaymentCmp.html
        │       ├── stripePaymentCmp.js
        
        │       └── stripePaymentCmp.js-meta.xml
        
        └── customMetadata/
        
            └── Stripe_Credentials.Stripe_Credential.md-meta.xml
            
⚙️ #**Configuration#**
1. Create Custom Metadata Type
Navigate to Setup → Custom Metadata Types → New Custom Metadata Type
Custom Metadata Type Details:

Label: Stripe Credentials
Plural Label: Stripe Credentials
Object Name: Stripe_Credentials

Add Custom Fields:
Field LabelField NameData TypeLengthPublisher KeyPublisher_Key__cText255Secret KeySecret_Key__cText255
2. Add Stripe API Keys

Go to Stripe Dashboard
Copy your Publishable key (starts with pk_test_)
Copy your Secret key (starts with sk_test_)
In Salesforce: Setup → Custom Metadata Types → Stripe Credentials → Manage Records
Create new record:

Label: Stripe_Credential
Stripe Credentials Name: Stripe_Credential
Publisher Key: Paste your publishable key
Secret Key: Paste your secret key



⚠️ Security Note: Never commit actual API keys to version control!
3. Configure Remote Site Settings
Setup → Security → Remote Site Settings → New Remote Site

Remote Site Name: Stripe_API
Remote Site URL: https://api.stripe.com
Active: ✅ Checked

4. Create Custom Field on OpportunityLineItem
Setup → Object Manager → Opportunity Product → Fields & Relationships → New

Data Type: Text
Field Label: Currency ISO Code Text
Field Name: CurrencyIsoCodeText
Length: 10
Default Value: USD

5. Add Quick Action to Opportunity

Setup → Object Manager → Opportunity → Buttons, Links, and Actions → New Action
Action Type: Lightning Component
Lightning Component: c:stripePaymentCmp
Label: Send to Payment
Name: Send_to_Payment
Add the action to Opportunity page layout

📖 Usage
Creating a Payment Link

Create or Open an Opportunity with products added
Ensure a Primary Contact is assigned to the Opportunity
Verify Contact has a valid email address
Click "Send to Payment" button on the Opportunity
The system will:

Fetch all products from the Opportunity
Create prices in Stripe
Generate a payment link
Send email to the customer's contact



User Workflow
1. Sales Rep adds products to Opportunity
           ↓
2. Sales Rep clicks "Send to Payment"
           ↓
3. System generates Stripe payment link
           ↓
4. Customer receives email with payment link
           ↓
5. Customer completes payment on Stripe
           ↓
6. Payment confirmation (can be tracked via webhooks)
🧪 Testing
Test Mode Setup

Ensure you're using test mode API keys (starting with sk_test_ and pk_test_)
Use Stripe test cards for testing

Test Card Numbers
ScenarioCard NumberCVCExpirySuccess4242 4242 4242 4242Any 3 digitsAny future dateDecline4000 0000 0000 0002Any 3 digitsAny future dateAuthentication4000 0025 0000 3155Any 3 digitsAny future date
Testing Steps

Create a test Opportunity with products
Add currency code to products:

apexList<OpportunityLineItem> items = [
    SELECT Id FROM OpportunityLineItem 
    WHERE OpportunityId = 'YOUR_OPP_ID'
];
for(OpportunityLineItem item : items) {
    item.CurrencyIsoCodeText__c = 'USD';
}
update items;

Click "Send to Payment" button
Check email for payment link
Complete payment with test card
Verify payment in Stripe Dashboard

Debug Logs
Enable debug logs for the Apex class:

Setup → Debug Logs → New
Select your user
Set Apex Code to DEBUG

🔧 **Troubleshooting**
Common Issues
Issue: "Argument cannot be null"
Solution: Ensure CurrencyIsoCodeText__c field has values on all OpportunityLineItems
Issue: "Unauthorized endpoint"
Solution: Verify Remote Site Settings are configured for https://api.stripe.com
Issue: "Invalid API Key"
Solution:

Check API keys in Custom Metadata
Ensure you're using test keys in test mode
Verify there are no extra spaces in the keys

Issue: No email received
Solution:

Verify Primary Contact is assigned to Opportunity
Check Contact has valid email address
Check email deliverability settings

Issue: Price shows as $0
Solution: Ensure OpportunityLineItems have TotalPrice values populated
Enable Detailed Logging
Add this to your Developer Console:
apexSystem.debug('Request Body: ' + requestBody);
System.debug('Response Status: ' + response.getStatusCode());
System.debug('Response Body: ' + response.getBody());

***Data Model:***

<img width="565" height="472" alt="Screenshot (1017)" src="https://github.com/user-attachments/assets/626ca540-1f40-4d73-b1e5-f327d4b4fe86" />

🤝*** Contributing***
Contributions are welcome! Please follow these steps:

Fork the repository
Create a feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)
Open a Pull Request

***Coding Standards***

Follow Salesforce Apex best practices
Include proper error handling
Add comments for complex logic
Test thoroughly before submitting PR

📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments

<img width="1366" height="662" alt="Screenshot (1016)" src="https://github.com/user-attachments/assets/4c9ca93d-571c-4479-82c3-6f398324b514" />
<img width="1245" height="528" alt="Screenshot (1015)" src="https://github.com/user-attachments/assets/bbba02c1-b952-4362-ae0b-8ef38abd8551" />
<img width="1366" height="654" alt="Screenshot (1014)" src="https://github.com/user-attachments/assets/d774aed8-3c7e-4cca-868b-6101bd225c42" />
<img width="1366" height="768" alt="Screenshot (1013)" src="https://github.com/user-attachments/assets/ff40930f-23dc-412a-84f3-6d9ccf2b9636" />
<img width="1360" height="680" alt="Screenshot (1012)" src="https://github.com/user-attachments/assets/5518882e-29f3-48ec-b42c-24c509e5c9e6" />
<img width="1366" height="662" alt="Screenshot (1011)" src="https://github.com/user-attachments/assets/d0606a8c-29be-4fbd-ba58-9f911727a936" />


Stripe API Documentation
Salesforce Lightning Web Components Guide
ApexHours Stripe Integration Tutorial

📞 Support
For issues and questions:

Open an issue on GitHub
Email: lalithadhandapani37@gmail.com
LinkedIn: https://www.linkedin.com/in/lalitha-dhandapani/

🔮 Future Enhancements

 Webhook integration for payment confirmations
 Support for Stripe subscriptions
 Payment history tracking in Salesforce
 Refund processing capability
 Multi-currency automatic conversion
 Custom email templates
 Payment analytics dashboard

📈 Version History

v1.0.0 (December 2025)

Initial release
Basic payment link generation
Email notification functionality
Test mode support


***Built by Lalitha D***
If you find this project helpful, please give it a ⭐ on GitHub!
