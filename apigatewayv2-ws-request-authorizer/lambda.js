exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    const response = {
        statusCode: 200,
        body: JSON.stringify('Hello User'),
    };
    return response;
};
