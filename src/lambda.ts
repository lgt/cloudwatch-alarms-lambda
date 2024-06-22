import { EventBridgeEvent, Handler, SNSEvent } from 'aws-lambda';
import logger from './logging/Logger';

export const handler: Handler = async (event: SNSEvent | EventBridgeEvent<any, any>, context) => {
  logger.info('EVENT: \n' + JSON.stringify(event, null, 2));
  return context.logStreamName;
};
