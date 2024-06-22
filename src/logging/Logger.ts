import pino from 'pino';
import config from '../config';

const logger: pino.Logger = pino({
  level: config.env.LOG_LEVEL,
  timestamp: pino.stdTimeFunctions.isoTime,
  serializers: {
    error: pino.stdSerializers.err,
  },
});
export default logger;
