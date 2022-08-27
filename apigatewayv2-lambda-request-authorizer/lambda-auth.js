exports.handler = async(event) => {
		if (event.headers.authorization == "secretToken") {
				console.log("allowed");
				return {
						"principalId": "abcdef", // The principal user identification associated with the token sent by the client.
						"policyDocument": {
								"Version": "2012-10-17",
								"Statement": [{
										"Action": "execute-api:Invoke",
										"Effect": "Allow",
										"Resource": event.routeArn
								}]
						},
						"context": {
								"accountAlias": "undefined",
								"stringKey": "value",
								"numberKey": 1,
								"booleanKey": true,
								"arrayKey": ["value1", "value2"],
								"mapKey": { "value1": "value2" }
						}
				};
		}
		else {
				console.log("denied");
				return {
						"principalId": "abcdef", // The principal user identification associated with the token sent by the client.
						"policyDocument": {
								"Version": "2012-10-17",
								"Statement": [{
										"Action": "execute-api:Invoke",
										"Effect": "Deny",
										"Resource": event.routeArn
								}]
						},
						"context": {
								"stringKey": "value",
								"numberKey": 1,
								"booleanKey": true,
								"arrayKey": ["value1", "value2"],
								"mapKey": { "value1": "value2" }
						}
				};
		}
};
