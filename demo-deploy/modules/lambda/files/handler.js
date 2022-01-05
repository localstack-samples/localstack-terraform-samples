/*
 * Sample Lambda Authorizer to validate tokens originating from
 * 3rd Party Identity Provider and generate an IAM Policy
 */

const apiPermissions = [
  {
    "arn": "arn:aws:execute-api:REGION:ACCOUNTID:my-api-gw", // NOTE: Replace with your API Gateway API ARN
    "resource": "my-resource", // NOTE: Replace with your API Gateway Resource
    "stage": "dev", // NOTE: Replace with your API Gateway Stage
    "httpVerb": "GET",
    "scope": "email"
  }
];

const defaultDenyAllPolicy = {
  "principalId":"user",
  "policyDocument":{
    "Version":"2012-10-17",
    "Statement":[
      {
        "Action":"execute-api:Invoke",
        "Effect":"Deny",
        "Resource":"*"
      }
    ]
  }
};

function generatePolicyStatement(apiName, apiStage, apiVerb, apiResource, action) {
  // Generate an IAM policy statement
  const statement = {};
  statement.Action = 'execute-api:Invoke';
  statement.Effect = action;
  const methodArn = apiName + "/" + apiStage + "/" + apiVerb + "/" + apiResource;
  statement.Resource = methodArn;
  return statement;
};

function generatePolicy(principalId, policyStatements) {
  // Generate a fully formed IAM policy
  const authResponse = {};
  authResponse.principalId = principalId;
  const policyDocument = {};
  policyDocument.Version = '2012-10-17';
  policyDocument.Statement = policyStatements;
  authResponse.policyDocument = policyDocument;
  return authResponse;
};

async function verifyAccessToken(accessToken) {
  /*
  * Verify the access token with your Identity Provider here (check if your
  * Identity Provider provides an SDK).
  *
  * This example assumes this method returns a Promise that resolves to
  * the decoded token, you may need to modify your code according to how
  * your token is verified and what your Identity Provider returns.
  */
};

function generateIAMPolicy(scopeClaims) {
  // Declare empty policy statements array
  const policyStatements = [];
  // Iterate over API Permissions
  for ( let i = 0; i < apiPermissions.length; i++ ) {
  // Check if token scopes exist in API Permission
  if ( scopeClaims.indexOf(apiPermissions[i].scope) > -1 ) {
  // User token has appropriate scope, add API permission to policy statements
  policyStatements.push(generatePolicyStatement(apiPermissions[i].arn, apiPermissions[i].stage,
    apiPermissions[i].httpVerb, apiPermissions[i].resource, "Allow"));
    }
  }
  // Check if no policy statements are generated, if so, create default deny all policy statement
  if (policyStatements.length === 0) {
    return defaultDenyAllPolicy;
  } else {
    return generatePolicy('user', policyStatements);
  }
};

exports.handler = async function(event, context) {
  // Declare Policy
  let iamPolicy = null;
  // Capture raw token and trim 'Bearer ' string, if present
  const token = event.authorizationToken.replace("Bearer ", "");
  // Validate token
  await verifyAccessToken(token).then(data => {
    // Retrieve token scopes
    const scopeClaims = data.claims.scp;
    // Generate IAM Policy
    iamPolicy = generateIAMPolicy(scopeClaims);
  })
  .catch(err => {
    console.log(err);
    iamPolicy = defaultDenyAllPolicy;
  });
  return iamPolicy;
};
