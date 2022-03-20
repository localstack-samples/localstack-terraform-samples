exports.handler = async(event) => {
		return {
				"isAuthorized": true,
				"context": {
						"exampleKey": "exampleValue"
				}
		}
}
