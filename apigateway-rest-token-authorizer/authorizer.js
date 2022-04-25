function generatePolicy(methodArn) {
  return {
    Version: "2012-10-17",
    Statement: [
      {
        Action: "execute-api:Invoke",
        Effect: "Allow",
        Resource: methodArn,
      },
    ],
  };
}

exports.handler = function(event, context, callback) {
		console.log(event);
		return {
				principalId: 'me',
				policyDocument: generatePolicy(event.methodArn)
    };
}
