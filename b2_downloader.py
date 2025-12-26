import os
import smtplib
from pathlib import Path
from email.mime.text import MIMEText
from datetime import datetime
from b2sdk.v2 import *

# Backblaze B2 credentials
B2_KEY_ID = os.environ.get('B2_APPLICATION_KEY_ID')
B2_APPLICATION_KEY = os.environ.get('B2_APPLICATION_KEY')
BUCKET_NAME = os.environ.get('B2_BUCKET_NAME')

# Email credentials
SMTP_SERVER = os.environ.get('SMTP_SERVER', 'smtp.gmail.com')
SMTP_PORT = int(os.environ.get('SMTP_PORT', 587))
EMAIL_SENDER = os.environ.get('EMAIL_SENDER')
EMAIL_PASSWORD = os.environ.get('EMAIL_PASSWORD')
EMAIL_RECIPIENT = os.environ.get('EMAIL_RECIPIENT')

DOWNLOAD_DIR = '/app/b2_downloads/'

def send_email(subject, message):
    """Send simple text email notification with date and time"""
    if not all([EMAIL_SENDER, EMAIL_PASSWORD, EMAIL_RECIPIENT]):
        print("Warning: Email credentials not set. Skipping email notification.")
        return False
    
    try:
        msg = MIMEText(message)
        msg['Subject'] = subject
        msg['From'] = EMAIL_SENDER
        msg['To'] = EMAIL_RECIPIENT

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()  # Secure the connection
            server.login(EMAIL_SENDER, EMAIL_PASSWORD)
            server.send_message(msg)
        
        print(f"Email notification sent successfully to {EMAIL_RECIPIENT}")
        return True
        
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False

def send_success_email(file_count):
    current_time = datetime.now()
    formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')
    
    subject = f'✅ Server Backup Download Complete - {formatted_time}'
    message = f'Server Backup Download Complete\n\nTime: {formatted_time}\nTotal files downloaded: {file_count}'
    
    return send_email(subject, message)

def send_failure_email(error_message):
    current_time = datetime.now()
    formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')
    
    subject = f'❌ Server Backup Download FAILED - {formatted_time}'
    message = f'Server Backup Download FAILED\n\nTime: {formatted_time}\nError: {error_message}'
    
    return send_email(subject, message)

def send_no_files_email():
    current_time = datetime.now()
    formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')
    
    subject = f'⚠️ No Backup Files Found - {formatted_time}'
    message = f'No files found in the bucket to download\n\nTime: {formatted_time}\nBucket: {BUCKET_NAME}'
    
    return send_email(subject, message)

def main():
    try:
        if not all([B2_KEY_ID, B2_APPLICATION_KEY, BUCKET_NAME]):
            error_msg = "B2_APPLICATION_KEY_ID, B2_APPLICATION_KEY, and B2_BUCKET_NAME must be set as env variables"
            print(f"Error: {error_msg}")
            send_failure_email(error_msg)
            return
        
        print("Initializing B2 API...")
        info = InMemoryAccountInfo()
        b2_api = B2Api(info, cache=AuthInfoCache(info))

        b2_api.authorize_account("production", B2_KEY_ID, B2_APPLICATION_KEY)
        print("Successfully initialized B2 account")

        bucket = b2_api.get_bucket_by_name(BUCKET_NAME)
        print(f"Successfully connected to bucket: '{BUCKET_NAME}'")

        if not os.path.exists(DOWNLOAD_DIR):
            os.makedirs(DOWNLOAD_DIR)
            print(f"Created download directory: '{DOWNLOAD_DIR}'")

        print("Starting file download process...")
        file_count = 0
        
        for file_info, folder_name in bucket.ls(latest_only=True, recursive=True):
            file_count += 1
            local_file_path = os.path.join(DOWNLOAD_DIR, file_info.file_name)

            local_folder_path = os.path.dirname(local_file_path)
            if not os.path.exists(local_folder_path):
                os.makedirs(local_folder_path)

            print(f"Downloading: {file_info.file_name} to {local_file_path}")

            download_dest = Path(local_file_path)
            downloaded_file = bucket.download_file_by_name(file_info.file_name)
            downloaded_file.save_to(download_dest)
            print(f"    -> Successfully downloaded {file_info.file_name}")
        
        if file_count == 0:
            print("No files found in the bucket to download.")
            send_no_files_email()
        else:
            print(f"\nDownload complete. Total files downloaded: {file_count}")
            send_success_email(file_count)
            
    except Exception as e:
        error_msg = str(e)
        print(f"Download process failed with error: {error_msg}")
        send_failure_email(error_msg)

if __name__ == "__main__":
    main()