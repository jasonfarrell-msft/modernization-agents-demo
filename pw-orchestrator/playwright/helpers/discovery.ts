import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(__dirname, '..', '.env'), override: true });

export interface AppConfig {
  appUrl: string;
  uploadRoute: string;
  allowedExtensions: string[];
  maxUploadMb: number;
  validationError: string;
}

export function getConfig(): AppConfig {
  return {
    appUrl: process.env.APP_URL || 'https://vm-legacy-swc.swedencentral.cloudapp.azure.com/',
    uploadRoute: process.env.UPLOAD_ROUTE || '/Outages/Upload/{id}',
    allowedExtensions: (process.env.ALLOWED_EXTENSIONS || '.pdf,.csv,.txt,.jpg,.jpeg,.png,.xlsx').split(','),
    maxUploadMb: parseInt(process.env.MAX_UPLOAD_MB || '25', 10),
    validationError: process.env.VALIDATION_ERROR || 'Please choose a file to upload.',
  };
}
