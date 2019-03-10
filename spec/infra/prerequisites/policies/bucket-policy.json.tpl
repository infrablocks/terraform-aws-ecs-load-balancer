{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${bucket_name}/${bucket_prefix}/AWSLogs/${account_id}/*",
      "Principal": {
        "AWS": [
          "${load_balancer_account_id}"
        ]
      }
    }
  ]
}
