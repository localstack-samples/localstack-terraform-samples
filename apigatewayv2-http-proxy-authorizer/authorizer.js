
exports.handler = function(event, context, callback) {
		return callback(null, allowPolicy(event.methodArn));
}


function denyAllPolicy(){
    return {
        "principalId": "*",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "*",
                    "Effect": "Deny",
                    "Resource": "*"
                }
            ]
        }
    }
}

function allowPolicy(methodArn){
    return {
        "principalId": "apigateway.amazonaws.com",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": "Allow",
                    "Resource": methodArn
                }
            ]
        }
    }
}
