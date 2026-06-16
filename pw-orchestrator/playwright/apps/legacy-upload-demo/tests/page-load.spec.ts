import { test, expect } from '@playwright/test';
import { getConfig } from '../../../helpers/discovery';

test.describe('Page Load', () => {
  test('homepage loads successfully', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBeLessThan(400);
    await expect(page.getByRole('heading')).toBeVisible();
  });

  test('list page loads', async ({ page }) => {
    const config = getConfig();
    const response = await page.goto(config.listRoute);
    expect(response?.status()).toBeLessThan(400);
    await expect(page.getByRole('heading')).toBeVisible();
    await expect(page.locator('table')).toBeVisible();
  });
});
