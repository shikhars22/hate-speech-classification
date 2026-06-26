import os


class GCloudSync:

    def sync_folder_to_gcloud(self, gcp_bucket_url, filepath, filename):

        command = f"aws s3 cp {filepath}/{filename} s3://{gcp_bucket_url}/{filename}"
        os.system(command)

    def sync_folder_from_gcloud(self, gcp_bucket_url, filename, destination):

        command = f"aws s3 cp s3://{gcp_bucket_url}/{filename} {destination}/{filename}"
        os.system(command)