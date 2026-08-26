#!/usr/bin/env python3
"""List S3 objects under a prefix, signing the request with SigV4 by hand.

Deliberately stdlib-only. The point of this script is to read S3 ground truth
from inside a Fusion task without installing anything and without going through
the Fusion mount, whose whole job is to serve a cached view. Images that ship
the AWS CLI set ENTRYPOINT ["aws"], which swallows the Nextflow task script, and
installing the CLI needs package repos that may not be reachable.

Usage:  s3ls.py <bucket> <region> <prefix>
Output: one "key\tsize" line per object, to stdout. Diagnostics to stderr.
"""

import datetime
import hashlib
import hmac
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

IMDS = "http://169.254.169.254"


def _sign(key, msg):
    return hmac.new(key, msg.encode(), hashlib.sha256).digest()


def credentials():
    """Environment first, then IMDSv2. Returns (akid, secret, token, source)."""
    if os.environ.get("AWS_ACCESS_KEY_ID"):
        return (
            os.environ["AWS_ACCESS_KEY_ID"],
            os.environ.get("AWS_SECRET_ACCESS_KEY", ""),
            os.environ.get("AWS_SESSION_TOKEN"),
            "environment",
        )

    req = urllib.request.Request(
        IMDS + "/latest/api/token",
        method="PUT",
        headers={"X-aws-ec2-metadata-token-ttl-seconds": "300"},
    )
    tok = urllib.request.urlopen(req, timeout=5).read().decode()
    hdr = {"X-aws-ec2-metadata-token": tok}

    base = IMDS + "/latest/meta-data/iam/security-credentials/"
    role = (
        urllib.request.urlopen(urllib.request.Request(base, headers=hdr), timeout=5)
        .read()
        .decode()
        .strip()
        .splitlines()[0]
    )
    body = urllib.request.urlopen(
        urllib.request.Request(base + role, headers=hdr), timeout=5
    ).read()
    doc = json.loads(body)
    return doc["AccessKeyId"], doc["SecretAccessKey"], doc["Token"], "IMDSv2/" + role


def list_objects(bucket, region, prefix, akid, secret, token):
    host = "%s.s3.%s.amazonaws.com" % (bucket, region)
    # Canonical query string: parameters sorted by name, values URI-encoded.
    # "list-type" sorts before "prefix".
    qs = "list-type=2&max-keys=1000&prefix=" + urllib.parse.quote(prefix, safe="")

    now = datetime.datetime.now(datetime.timezone.utc)
    amzdate = now.strftime("%Y%m%dT%H%M%SZ")
    datestamp = now.strftime("%Y%m%d")
    payload_hash = hashlib.sha256(b"").hexdigest()

    headers = {
        "host": host,
        "x-amz-content-sha256": payload_hash,
        "x-amz-date": amzdate,
    }
    if token:
        headers["x-amz-security-token"] = token

    signed = ";".join(sorted(headers))
    canon_headers = "".join("%s:%s\n" % (k, headers[k]) for k in sorted(headers))
    canon_req = "GET\n/\n%s\n%s\n%s\n%s" % (qs, canon_headers, signed, payload_hash)

    scope = "%s/%s/s3/aws4_request" % (datestamp, region)
    to_sign = "AWS4-HMAC-SHA256\n%s\n%s\n%s" % (
        amzdate,
        scope,
        hashlib.sha256(canon_req.encode()).hexdigest(),
    )

    k = _sign(("AWS4" + secret).encode(), datestamp)
    k = _sign(k, region)
    k = _sign(k, "s3")
    k = _sign(k, "aws4_request")
    sig = hmac.new(k, to_sign.encode(), hashlib.sha256).hexdigest()

    headers["Authorization"] = (
        "AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s"
        % (akid, scope, signed, sig)
    )

    url = "https://%s/?%s" % (host, qs)
    try:
        body = urllib.request.urlopen(
            urllib.request.Request(url, headers=headers), timeout=20
        ).read().decode()
    except urllib.error.HTTPError as exc:
        sys.stderr.write("HTTP %s from S3\n%s\n" % (exc.code, exc.read().decode()[:800]))
        raise

    out = []
    for chunk in re.finditer(r"<Contents>(.*?)</Contents>", body, re.S):
        key = re.search(r"<Key>(.*?)</Key>", chunk.group(1)).group(1)
        size = re.search(r"<Size>(\d+)</Size>", chunk.group(1)).group(1)
        out.append((key, int(size)))
    if "<IsTruncated>true</IsTruncated>" in body:
        sys.stderr.write("NOTE: listing truncated at 1000 keys\n")
    return out


def main():
    if len(sys.argv) != 4:
        sys.stderr.write(__doc__)
        return 2

    bucket, region, prefix = sys.argv[1], sys.argv[2], sys.argv[3]
    try:
        akid, secret, token, source = credentials()
    except Exception as exc:  # noqa: BLE001 - any failure here is fatal and worth naming
        sys.stderr.write(
            "no usable credentials: neither AWS_ACCESS_KEY_ID in the environment "
            "nor IMDSv2 at %s worked (%s: %s)\n" % (IMDS, type(exc).__name__, exc)
        )
        return 3
    sys.stderr.write("credentials from %s\n" % source)

    for key, size in list_objects(bucket, region, prefix, akid, secret, token):
        sys.stdout.write("%s\t%d\n" % (key, size))
    return 0


if __name__ == "__main__":
    sys.exit(main())
