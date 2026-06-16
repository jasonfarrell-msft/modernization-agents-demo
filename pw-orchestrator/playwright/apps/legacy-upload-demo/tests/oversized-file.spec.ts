import { test, expect } from '@playwright/test';
import { uniqueFilename, createFileBuffer, uploadFile, hasVisibleFailureSignal } from '../../../helpers/test-utils';
import { getConfig } from '../../../helpers/discovery';
import { navigateToUploadPage, hasAppFailureSignal } from '../app-helpers';

test.describe('Oversized File', () => {
  test('rejects file exceeding max upload size', async ({ page }) => {
    const config = getConfig();
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('oversized', '.pdf');
    const oversizedBytes = (config.maxUploadMb + 1) * 1024 * 1024;
    const content = createFileBuffer(oversizedBytes);

    // Legacy apps may reject oversized uploads at different layers
    const responsePromise = page.waitForResponse(
      (resp) => resp.request().method() === 'POST' && resp.url().includes('Upload'),
      { timeout: 30_000 }
    ).catch(() => null);

    await uploadFile(page, fileName, content, { mimeType: 'application/pdf' });

    const response = await responsePromise;

    const isRequestRejection = response && response.status() >= 400;
    const hasPageError = await hasAppFailureSignal(page);
    const hasGenericError = await hasVisibleFailureSignal(page, [
      /maximum|too large|entity|request/i,
    ]);

    const failureDetected = isRequestRejection || hasPageError || hasGenericError;
    expect(failureDetected).toBe(true);

    // Should NOT show a success message
    const hasSuccess = await page.getByText(/uploaded.*to outage/i)
      .first().isVisible({ timeout: 1000 }).catch(() => false);
    expect(hasSuccess).toBe(false);
  });
});
