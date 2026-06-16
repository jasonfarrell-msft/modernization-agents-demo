import { test, expect } from '@playwright/test';
import { getConfig } from '../../../helpers/discovery';
import { navigateToUploadPage, uploadPagePattern } from '../app-helpers';

test.describe('Missing File', () => {
  test('shows validation error when no file is selected', async ({ page }) => {
    await navigateToUploadPage(page);

    await page.getByRole('button', { name: 'Upload' }).click();

    const config = getConfig();
    await expect(page.getByText(config.validationError)).toBeVisible();
    expect(page.url()).toMatch(uploadPagePattern());
  });
});
