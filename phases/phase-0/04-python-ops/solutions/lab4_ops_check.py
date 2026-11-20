#!/usr/bin/env python3
"""Check a list of URLs, log what happened, and exit non-zero if anything is wrong.

Exit codes: 0 = all healthy, 1 = at least one URL unhealthy or unreachable, 2 = couldn't read the URL file.
"""
import argparse
import logging
import os
import sys

import requests

log = logging.getLogger("ops_check")


def setup_logging(log_file, verbose):
    formatter = logging.Formatter("%(asctime)s %(levelname)-7s %(message)s")
    handlers = [logging.StreamHandler(sys.stderr), logging.FileHandler(log_file)]
    for handler in handlers:
        handler.setFormatter(formatter)
        log.addHandler(handler)
    log.setLevel(logging.DEBUG if verbose else logging.INFO)


def read_urls(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


def check(url, timeout):
    """Return True if the URL answered with a 2xx/3xx status; log the reason if not."""
    try:
        response = requests.get(url, timeout=timeout)
    except requests.exceptions.Timeout:
        log.error("%s -> no answer within %.1fs (timeout)", url, timeout)
        return False
    except requests.exceptions.ConnectionError as exc:
        log.error("%s -> could not connect: %s", url, exc)
        return False
    if response.ok:
        log.info("%s -> %d", url, response.status_code)
        return True
    log.warning("%s -> %d (body: %s)", url, response.status_code, response.text[:80])
    return False


def main():
    parser = argparse.ArgumentParser(description="Check each URL in a file.")
    parser.add_argument("urls_file", help="text file with one URL per line")
    parser.add_argument("--timeout", type=float, default=3.0, help="seconds to wait for each URL")
    parser.add_argument("--log-file", default="ops_check.log", help="where to write the log")
    parser.add_argument("--verbose", action="store_true", help="also log DEBUG messages")
    args = parser.parse_args()
    setup_logging(args.log_file, args.verbose)

    try:
        urls = read_urls(args.urls_file)
    except FileNotFoundError:
        log.error("URL file not found: %s (current folder: %s)", args.urls_file, os.getcwd())
        return 2

    log.info("checking %d URL(s) from %s", len(urls), args.urls_file)
    failures = sum(1 for url in urls if not check(url, args.timeout))
    log.info("done: %d ok, %d failed", len(urls) - failures, failures)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
