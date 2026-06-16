import { test, expect } from '@playwright/test';
import { uniqueFilename, createFileBuffer, uploadFile, hasVisibleFailureSignal } from '../../../helpers/test-utils';
import { navigateToUploadPage, uploadPagePattern, hasAppFailureSignal } from '../app-helpers';

test.describe('Invalid Extension', () => {
  test('rejects a .exe file upload', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('malware', '.exe');
    const content = createFileBuffer(512);

    await uploadFile(page, fileName, content);

    const hasError = await hasAppFailureSignal(page) || await hasVisibleFailureSignal(page);
    expect(hasError).toBe(true);
    expect(page.url()).toMatch(uploadPagePattern());
  });

  test('rejects a .bat file upload', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('script', '.bat');
    const content = createFileBuffer(128, 'echo bad');

    await uploadFile(page, fileName, content);

    const hasError = await hasAppFailureSignal(page) || await hasVisibleFailureSignal(page);
    expect(hasError).toBe(true);
    expect(page.url()).toMatch(uploadPagePattern());
  });
});
