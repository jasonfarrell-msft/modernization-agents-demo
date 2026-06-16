import { test, expect } from '@playwright/test';
import { navigateToUploadPage, uploadFile, uniqueFilename, createFileBuffer, hasVisibleFailureSignal } from '../helpers/upload-helpers';

test.describe('Invalid Extension', () => {
  test('rejects a .exe file upload', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('malware', '.exe');
    const content = createFileBuffer(512);

    await uploadFile(page, fileName, content, 'application/octet-stream');

    // Should stay on upload page with a visible error
    const hasError = await hasVisibleFailureSignal(page);
    expect(hasError).toBe(true);

    // Should NOT have navigated to details
    expect(page.url()).toMatch(/\/Outages\/Upload\/\d+/);
  });

  test('rejects a .bat file upload', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('script', '.bat');
    const content = createFileBuffer(128, 'echo bad');

    await uploadFile(page, fileName, content, 'application/x-msdos-program');

    const hasError = await hasVisibleFailureSignal(page);
    expect(hasError).toBe(true);
    expect(page.url()).toMatch(/\/Outages\/Upload\/\d+/);
  });
});
