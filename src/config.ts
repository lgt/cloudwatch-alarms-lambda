import dotenv from 'dotenv';
import { z } from 'zod';
import logger from './logging/Logger';

try {
  dotenv.config();
} catch (error) {
  logger.error('Error loading .env file');
}

const envSchema = z.object({
  NODE_ENV: z.string(),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('debug'),
});

const env = envSchema.parse(process.env);

const config = {
  env: env,
};

export default config;
