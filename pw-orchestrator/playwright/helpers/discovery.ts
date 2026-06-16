import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(__dirname, '..', '.env'), override: true });

export interface AppConfig {
  appUrl: string;
  listRoute: string;
  uploadRoute: string;
  allowedExtensions: string[];
  maxUploadMb: number;
  validationError: string;
}

export function getConfig(): AppConfig {
  const appUrl = process.env.APP_URL;
  const listRoute = process.env.LIST_ROUTE;
  const uploadRoute = process.env.UPLOAD_ROUTE;

  if (!appUrl) throw new Error('APP_URL not set — run via orchestrate.sh or create .env');
  if (!listRoute) throw new Error('LIST_ROUTE not set — check adapter discovery');
  if (!uploadRoute) throw new Error('UPLOAD_ROUTE not set — check adapter discovery');

  return {
    appUrl,
    listRoute,
    uploadRoute,
    allowedExtensions: (process.env.ALLOWED_EXTENSIONS || '').split(',').filter(Boolean),
    maxUploadMb: parseInt(process.env.MAX_UPLOAD_MB || '0', 10),
    validationError: process.env.VALIDATION_ERROR || '',
  };
}
