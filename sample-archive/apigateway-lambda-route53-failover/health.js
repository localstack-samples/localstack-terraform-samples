exports.handler = async (event, context) => {
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: "Health from " + context.invokedFunctionArn
        }, null, 2),
    };
};
