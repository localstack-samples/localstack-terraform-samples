exports.handler = async (event, context) => {
	console.log('Event: ', event)
	return { "message": "Hello from Lambda!" }
}
