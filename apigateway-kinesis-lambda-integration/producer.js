// kinesis javascript sdk put record lambda

const AWS = require('aws-sdk');
const kinesis = new AWS.Kinesis();


exports.handler = (event, context, callback) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var params = {
        Data: JSON.stringify(event),
        PartitionKey: 'stream-3',
        StreamName: 'stream'
    };
    kinesis.putRecord(params, function(err, data) {
        if (err) {
            console.log(err, err.stack);
            callback(err);
        } else {
            console.log(data);
            callback(null, data);
        }
    });
};
