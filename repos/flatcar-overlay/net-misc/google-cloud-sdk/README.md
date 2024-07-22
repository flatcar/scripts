Some notes about the google-cloud-sdk package:

- It is only a part of our SDK image, as we are using it for uploading
  built artifacts to our google storage. So this is not a user-facing
  package. Maybe at some point it can be dropped if we decide to
  always pull a docker image that contains the google-cloud-sdk - we
  already do it in some places. The GCE OEM image has bash aliases
  that also download the docker image and run gcloud/gsutil from it.

- Since it's only for "internal" use, we don't install all the
  tools. We only keep gcloud and gsutil. Not sure if we even use the
  former, maybe could be dropped later. But this is the reason why we
  remove some of the code in src_prepare - we don't need bq, for
  example.

- The scripts in the "files" directory are really cut-down versions of
  "gsutil" and "gcloud" scripts coming from google-could-sdk
  tarball. The scripts in tarball are doing a bunch of discoveries to
  set up some environment variables - we cut the chase and set them to
  a good known values.

- We have a runtime dependency on crcmod, because we want to make sure
  that gsutil will use a compiled version of crc computing routines
  instead of python ones - the latter are super-slow and gsutil
  disables some features if they are used. Not sure if we use those
  features, though (uploading composite objects).

- We used to have a runtime dependency on pyopenssl, which is used by
  `gsutil signurl` command. We dropped it again, because the only uses
  of the signurl command are with gsutil coming from docker images
  instead of this package.
