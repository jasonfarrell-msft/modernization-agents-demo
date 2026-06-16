import { test, expect } from '@playwright/test';
import { navigateToUploadPage, uploadFile, uniqueFilename, createFileBuffer, hasVisibleFailureSignal } from '../helpers/upload-helpers';
import { getConfig } from '../helpers/discovery';

test.describe('Oversized File', () => {
  test('rejects file exceeding max upload size', async ({ page }) => {
    const config = getConfig();
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('oversized', '.pdf');
    // Create a file slightly over the limit
    const oversizedBytes = (config.maxUploadMb + 1) * 1024 * 1024;
    const content = createFileBuffer(oversizedBytes);

    // Attempt upload — legacy apps may handle this at different layers:
    // 1. Inline validation on the upload page
    // 2. Redirect to error/details page
    // 3. Request-level rejection (HTTP 413 or IIS large-request block)
    const responsePromise = page.waitForResponse(
      (resp) => resp.url().includes('/Outages/Upload') && resp.request().method() === 'POST',
      { timeout: 30_000 }
    ).catch(() => null);

    await uploadFile(page, fileName, content, 'application/pdf');

    const response = await responsePromise;

    // Accept any of the valid legacy failure paths
    const isRequestRejection = response && response.status() >= 400;
    const hasPageError = await hasVisibleFailureSignal(page);
    const isOnUploadPage = /\/Outages\/Upload\/\d+/.test(page.url());
    const hasErrorText = await page.getByText(/maximum|too large|entity|request/i)
      .first().isVisible({ timeout: 3000 }).catch(() => false);

    // At least one failure signal must be present
    const failureDetected = isRequestRejection || hasPageError || hasErrorText;
    expect(failureDetected).toBe(true);

    // Should NOT show a success message
    const hasSuccess = await page.getByText(/uploaded.*to outage/i)
      .first().isVisible({ timeout: 1000 }).catch(() => false);
    expect(hasSuccess).toBe(false);
  });
});
