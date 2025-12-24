import os
from pathlib import Path
from b2sdk.v2 import *

B2_KEY_ID = os.environ.get('B2_APPLICATION_KEY_ID')
B2_APPLICATION_KEY = os.environ.get('B2_APPLICATION_KEY')
BUCKET_NAME = os.environ.get('B2_BUCKET_NAME')

DOWNLOAD_DIR = '/app/b2_downloads/'

def main():
    if not all([B2_KEY_ID, B2_APPLICATION_KEY, BUCKET_NAME]):
        print("Error: B2_APPLICATION_KEY_ID, B2_APPLICATION_KEY, and B2_BUCKET_NAME must be set as env variables")
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
        try:
            downloaded_file = bucket.download_file_by_name(file_info.file_name)
            downloaded_file.save_to(download_dest)
            print(f"    -> Successfully downloaded {file_info.file_name}")
        except Exception as e:
            print(f"    -> Failed to download {file_info.file_name}. Error: {e}")
    
    if file_count == 0:
        print("No files found in the bucket to download.")
    else:
        print(f"\nDownload complete. Total files processed: {file_count}")

if __name__ == "__main__":
    main()