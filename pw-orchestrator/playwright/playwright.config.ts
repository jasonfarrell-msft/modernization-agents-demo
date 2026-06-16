import { defineConfig, devices } from '@playwright/test';
import * as path from 'path';

require('dotenv').config({ path: path.resolve(__dirname, '.env') });

const baseURL = process.env.APP_URL || 'https://vm-legacy-swc.swedencentral.cloudapp.azure.com/';

export default defineConfig({
  testDir: './tests',
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
