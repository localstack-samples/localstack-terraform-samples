exports.lambdaHandler = async (event, _context) => {
  const name = event?.pathParameters?.name || 'World';

  return {
    'statusCode': 200,
    'body': JSON.stringify({
      message: `Hello, ${name}`,
      event: event
    })
  }
};