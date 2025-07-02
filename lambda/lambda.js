const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const { httpMethod, body, pathParameters } = event;
        const tableName = process.env.TABLE_NAME;
        
        let response;
        
        switch (httpMethod) {
            case 'GET':
                if (pathParameters && pathParameters.id) {
                    response = await dynamodb.get({
                        TableName: tableName,
                        Key: { id: pathParameters.id }
                    }).promise();
                } else {
                    response = await dynamodb.scan({
                        TableName: tableName
                    }).promise();
                }
                break;
                
            case 'POST':
                const item = JSON.parse(body);
                item.id = item.id || Date.now().toString();
                item.timestamp = new Date().toISOString();
                
                await dynamodb.put({
                    TableName: tableName,
                    Item: item
                }).promise();
                
                response = { message: 'Item created', item };
                break;
                
            case 'DELETE':
                if (pathParameters && pathParameters.id) {
                    await dynamodb.delete({
                        TableName: tableName,
                        Key: { id: pathParameters.id }
                    }).promise();
                    response = { message: 'Item deleted' };
                }
                break;
                
            default:
                response = { message: 'Method not allowed' };
        }
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(response)
        };
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({ error: error.message })
        };
    }
};
