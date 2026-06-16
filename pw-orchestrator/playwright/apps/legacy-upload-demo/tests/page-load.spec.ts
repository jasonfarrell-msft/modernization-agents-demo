import { test, expect } from '@playwright/test';

test.describe('Page Load', () => {
  test('homepage loads successfully', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBeLessThan(400);
    await expect(page.getByRole('heading')).toBeVisible();
  });

  test('outages list loads', async ({ page }) => {
    const response = await page.goto('/Outages');
    expect(response?.status()).toBeLessThan(400);
    await expect(page.getByRole('heading', { name: /outage/i })).toBeVisible();
    await expect(page.locator('table')).toBeVisible();
  });
});
