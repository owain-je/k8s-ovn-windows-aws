resource "aws_s3_bucket" "bucket" {
  bucket = "${var.cluster-name}-k8s-state"
  acl    = "private"

  tags {
    Name        = "${var.cluster-name}-k8s-state"
  }
}

resource "aws_s3_bucket_object" "object" {
  bucket = "${aws_s3_bucket.bucket.id}"
  key    = "master-startup.sh"
  source = "startup-master-node.sh"
  etag   = "${md5(file("startup-master-node.sh"))}"
}