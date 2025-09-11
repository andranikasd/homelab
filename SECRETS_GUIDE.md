# Secrets Setup Guide

This guide will help you obtain and configure all the secrets needed for the Edge Stack.

## Required Secrets

### 1. OAuth2 Proxy Credentials

#### Google OAuth2 Setup (Recommended)

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create or Select Project**
   - Click "Select a project" at the top
   - Click "New Project" or select existing project
   - Name: "Edge Stack OAuth2"

3. **Enable Google+ API**
   - Go to "APIs & Services" > "Library"
   - Search for "Google+ API"
   - Click on it and press "Enable"

4. **Create OAuth2 Credentials**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client IDs"
   - Application type: "Web application"
   - Name: "Edge Stack OAuth2"
   - Authorized redirect URIs: `https://auth.mxnq.net/oauth2/callback`
   - Click "Create"

5. **Copy Credentials**
   - Copy the "Client ID" (for oauth2_proxy_client_id)
   - Copy the "Client Secret" (for oauth2_proxy_client_secret)

#### Alternative: GitHub OAuth2

1. **Go to GitHub Settings**
   - Visit: https://github.com/settings/developers
   - Click "New OAuth App"

2. **Create OAuth App**
   - Application name: "Edge Stack"
   - Homepage URL: `https://mxnq.net`
   - Authorization callback URL: `https://auth.mxnq.net/oauth2/callback`
   - Click "Register application"

3. **Copy Credentials**
   - Copy the "Client ID" (for oauth2_proxy_client_id)
   - Generate and copy the "Client Secret" (for oauth2_proxy_client_secret)

### 2. CrowdSec API Key

1. **Sign up for CrowdSec**
   - Visit: https://app.crowdsec.net/
   - Click "Sign Up" and create an account

2. **Create API Key**
   - After login, go to "API Keys" section
   - Click "Create API Key"
   - Name: "Edge Stack"
   - Copy the generated API key (for crowdsec_api_key)

### 3. SSL Certificates (Optional)

Since we're using Let's Encrypt, you can use placeholders for these:

- **Traefik Certificate**: Use "placeholder" (Let's Encrypt will generate real certs)
- **Traefik Private Key**: Use "placeholder" (Let's Encrypt will generate real keys)

## Quick Setup

Run the interactive setup script:

```bash
./setup-secrets.sh
```

This script will prompt you for each secret value and encrypt them automatically.

## Manual Setup

If you prefer to set up secrets manually:

1. **Decrypt existing files**:
   ```bash
   sops -d -i secrets/traefik_cert.encrypted
   sops -d -i secrets/traefik_key.encrypted
   sops -d -i secrets/oauth2_proxy_client_id.encrypted
   sops -d -i secrets/oauth2_proxy_client_secret.encrypted
   sops -d -i secrets/crowdsec_api_key.encrypted
   ```

2. **Edit each file** with your actual values

3. **Re-encrypt**:
   ```bash
   sops -e -i secrets/traefik_cert.encrypted
   sops -e -i secrets/traefik_key.encrypted
   sops -e -i secrets/oauth2_proxy_client_id.encrypted
   sops -e -i secrets/oauth2_proxy_client_secret.encrypted
   sops -e -i secrets/crowdsec_api_key.encrypted
   ```

## Verification

After setting up secrets, verify they're encrypted:

```bash
# Check that files are encrypted (should show binary/encrypted content)
file secrets/*.encrypted

# Verify SOPS can decrypt them
sops -d secrets/oauth2_proxy_client_id.encrypted
```

## Security Notes

- **Never commit unencrypted secrets** to Git
- **Backup your age key**: `~/.config/sops/age/keys.txt`
- **Rotate secrets regularly** for security
- **Use strong, unique values** for each secret

## Troubleshooting

### SOPS Decryption Fails
```bash
# Check age key exists
ls -la ~/.config/sops/age/keys.txt

# Regenerate if needed
age-keygen -o ~/.config/sops/age/keys.txt
```

### OAuth2 Redirect Mismatch
- Ensure redirect URL exactly matches: `https://auth.mxnq.net/oauth2/callback`
- Check domain DNS is pointing to your server IP

### CrowdSec API Key Invalid
- Verify key is copied correctly (no extra spaces)
- Check key hasn't expired in CrowdSec console
