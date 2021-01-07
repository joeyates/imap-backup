# Setting up GMail Authentication for imap_backup

# Create a Google project

Go to https://console.developers.google.com

Select "Credentials".

![Credential screen](01-credentials-screen.png)

Select "CREATE PROJECT".

![New project](02-new-project.png)

Set or accept the "Project name",

And optionally do the same with the "Project ID",

Leave "Location" on "No organization",

Click "CREATE".

![Initial project credentials](03-initial-credentials-for-project.png)

Click "+ CREATE CREDENTIALS".

![Credential type selection](04-credential-type-selection.png)

Select "OAuth client ID".

![Can't create credentials before setting up the consent screen](05-cant-create-without-consent-setup.png)

Click "CONFIGURE CONSENT SCREEN".

![User type selection](06-user-type-selection.png)

Select "External",

Click "CREATE".

![Consent screen form](07-consent-screen-form.png)

Fill in "App name",

Select your email as "User support email",

Type in your email at the bottom under "Developer contact information",

Click "SAVE AND CONTINUE".

![App scopes](08-app-scopes.png)

Click "ADD OR REMOVE SCOPES".

![Scope selection](09-scope-selection.png)

Under "Manually add scopes", type "https://mail.google.com/",

Click "ADD TO TABLE",

Click "UPDATE".

![Updated app scopes](10-updated-app-scopes.png)

Click "SAVE AND CONTINUE".

![Test users](11-test-users.png)

Click "+ ADD USERS".

![Add users](12-add-users.png)

Type in your email,

Click "SAVE AND CONTINUE",

Click "BACK TO DASHBOARD",

Click "Credentials" in the menu

And then click "+ CREATE CREDENTIALS" again,

And select "OAuth client ID" again.

![Create OAuth client](13-create-oauth-client.png)

This time you will be able to proceed.

![Application details](14-application-details.png)

Select "TVs and limited input devices",

Click "CREATE",

Copy both "Your Client ID"

And "Your Client Secret".

# Set up imap_backup

Run `imap_backup setup`.

![Initial imap_backup menu](16-initial-menu.png)

Choose 'add account'.

![Type in your email address](17-inputting-the-email-address.png)

Type in your GMail address.

Note: if you have a custom domain (GSuite) address,
e.g. "me@mycompany.com", you now need to
choose 'server' and
type in 'imap.gmail.com'.

![Choose password](18-choose-password.png)

Choose `password`.

![Supply client info](19-supply-client-info.png)

Type your "Client ID" and "Client Secret",

Next you will be shown a URL to open in your browser.

![Choose GMail account](20-choose-gmail-account.png)

If you have more than one GMail account you will need to choose which
you are configuring.

![Accept warnings](21-accept-warnings.png)

As the project "app" is in test mode,
you'll need to accept to ignore this warning.

Click "Advanced",

Then click "Go to XXXYYYZZZ (unsafe)"

![Grant access](22-grant-access.png)

Choose "Allow".

![Confirm choices](24-confirm-choices.png)

Choose "Allow".

![Success code screen](25-success-code.png)

Click on the copy logo to copy the success code.

![Paste the code](26-type-code-into-imap_backup.png)

Paste the success code into imap_backup.

Finally, choose 'test connection'.

If all has gone well you should see this:

![Connection successful](27-success.png)

Now choose 'return to main menu',

Then 'save and exit'.

Your imap_backup is now configured to back up your GMail.
