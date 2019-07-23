const awsmobile =  {
  "aws_project_region": "${aws_region}",
  "aws_cognito_region": "${aws_region}",
  "aws_user_pools_id": "${user_pool_id}",
  "aws_user_pools_web_client_id": "${user_pool_client_id}",
  "aws_cloud_logic_custom": [
    {
      "name": "api",
      "endpoint": "${api_endpoint}",
      "region": "${aws_region}"
    }
  ],
};

export default awsmobile;
