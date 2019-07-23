#!/usr/bin/env bash

# Collect credentials and login
eval $(aws ecr get-login --region ${region} --no-include-email --profile ${profile})

# Upload the image
docker tag ${image_tag}:${image_tag} ${repository_url}:${image_tag}
docker push ${repository_url}:${image_tag}
