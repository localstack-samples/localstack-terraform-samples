exports.handler = (event, context, callback) => {
  console.log(event)
  if (event.headers.authorization === "secretToken") {
    console.log("allowed");
    let policy = {
      "principalId": "abcdef", // The principal user identification associated with the token sent by the client.
      "policyDocument": {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Action": "execute-api:Invoke",
            "Effect": "Allow",
            "Resource": event["methodArn"]
          }
        ]
      },
      "context": {
        "accountAlias": "account-alias",
        "accountId": "12345-2345",
        "permissions": "all-perms",
        "projectId": "project-1234",
        "tenantId": "tenant-1234",
        "userId": "user-1234",
        "stringKey": "value",
        "numberKey": 1,
        "booleanKey": true
      }
    };
    console.log("policy: ", JSON.stringify(policy));
    callback(null, policy);
  } else {
    console.log("denied");
    let policy = {
      "principalId": "abcdef", // The principal user identification associated with the token sent by the client.
      "policyDocument": {
        "Version": "2012-10-17",
        "Statement": [{
          "Action": "execute-api:Invoke",
          "Effect": "Deny",
          "Resource": event["methodArn"]
        }]
      },
      "context": {
        "stringKey": "value",
        "numberKey": 1,
        "booleanKey": true
      }
    };
    callback(null, policy);
  }
};
