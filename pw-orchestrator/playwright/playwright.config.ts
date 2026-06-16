import { defineConfig, devices } from '@playwright/test';
import * as path from 'path';

require('dotenv').config({ path: path.resolve(__dirname, '.env') });

const baseURL = process.env.APP_URL;
const appName = process.env.APP_NAME;

if (!baseURL) throw new Error('APP_URL not set — run via orchestrate.sh or create .env');
if (!appName) throw new Error('APP_NAME not set — run via orchestrate.sh or create .env');

export default defineConfig({
  testDir: `./apps/${appName}/tests`,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  workers: 1,
  reporter: [
    ['html', { open: 'never', outputFolder: '../results/html-report' }],
    ['json', { outputFile: '../results/test-results.json' }],
    ['list'],
  ],
  use: {
    baseURL,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  outputDir: '../results/test-artifacts',
});
