import { test, expect } from '@playwright/test';
import { navigateToUploadPage } from '../app-helpers';

test.describe('Upload Form', () => {
  test('upload form renders with expected elements', async ({ page }) => {
    await navigateToUploadPage(page);

    await expect(page.getByRole('heading', { name: /upload/i })).toBeVisible();
    await expect(page.getByLabel('File')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Upload' })).toBeVisible();
    await expect(page.getByRole('link', { name: 'Cancel' })).toBeVisible();
  });

  test('upload form shows outage ticket number', async ({ page }) => {
    await navigateToUploadPage(page);
    await expect(page.getByText(/Outage\s+OUT-\d{4}-\d+/i)).toBeVisible();
  });
});
