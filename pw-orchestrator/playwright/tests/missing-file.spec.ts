import { test, expect } from '@playwright/test';
import { navigateToUploadPage, hasVisibleFailureSignal } from '../helpers/upload-helpers';
import { getConfig } from '../helpers/discovery';

test.describe('Missing File', () => {
  test('shows validation error when no file is selected', async ({ page }) => {
    await navigateToUploadPage(page);

    // Submit without selecting a file
    await page.getByRole('button', { name: 'Upload' }).click();

    // Should show the known validation message
    const config = getConfig();
    await expect(page.getByText(config.validationError)).toBeVisible();

    // Should remain on upload page
    expect(page.url()).toMatch(/\/Outages\/Upload\/\d+/);
  });
});
