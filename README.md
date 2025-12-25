# Backblaze B2 Backup Downloader

Docker stack for downloading backup files from Backblaze B2 storage and Gmail email notification.

## Quick Start

1. **Clone and configure**

   ```bash
   git@github.com:saundersdigital/backblaze-backup-downloader.git
   cd backblaze-backup-downloader
   ```

2. **Edit Backblaze credentials**

   Create a `.env` with your Backblaze and Gmail details, it's advised to create a dedicated api key inside Backblaze for this script that has read only access to your B2 bucket:

   ```env
   B2_APPLICATION_KEY_ID=application-key-id
   B2_APPLICATION_KEY=application-key
   B2_BUCKET_NAME=bucket-name

   EMAIL_SENDER=your_email@gmail.com
   EMAIL_PASSWORD=your_app_password_here
   EMAIL_RECIPIENT=recipient_email@example.com
   ```

3. **Run the downloader**

   ```bash
   chmod +x run.sh
   ./run.sh
   ```

## Notes

- Backblaze only allow 1Gb of egress `each day` free to their API, once you go over that free 1Gb there will be charges incurred

## Resources

- **BackBlaze B2**: [B2 Cloud Storage](https://www.backblaze.com/cloud-storage)
- **Gmail App Password Setup**: [Gmail App Password Setup*](https://support.google.com/mail/answer/185833?hl=en)