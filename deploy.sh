#!/bin/bash

aws amplify start-deployment --app-id d1l6cvzau7bwfq --branch-name prod --source-url s3://calebarg.net/ --source-url-type BUCKET_PREFIX
