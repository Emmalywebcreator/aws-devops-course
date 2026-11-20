#!/usr/bin/env python3
"""Count the S3 buckets one AWS profile can see, and log the result. Credentials never appear in this file."""
import argparse
import logging
import sys

import boto3
from botocore.exceptions import BotoCoreError, ClientError

log = logging.getLogger("s3_report")


def main():
    parser = argparse.ArgumentParser(description="List S3 buckets (read-only) and log the count.")
    parser.add_argument("--profile", help="AWS CLI profile to use (default: the SDK's normal lookup)")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)-7s %(message)s")

    try:
        session = boto3.Session(profile_name=args.profile)
        buckets = session.client("s3").list_buckets()["Buckets"]
    except (BotoCoreError, ClientError) as exc:
        log.error("could not list buckets: %s", exc)
        return 1

    log.info("found %d bucket(s)", len(buckets))
    for bucket in buckets:
        log.info("bucket: %s", bucket["Name"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
