exports.handler = function(event, context, callback) {
  console.log('Received event:', JSON.stringify(event, null, 2));
  callback(null, "Kinesis Consumer");
};
