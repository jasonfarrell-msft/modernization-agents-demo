import { test, expect } from '@playwright/test';
import { navigateToUploadPage, uploadFile, uniqueFilename, createFileBuffer } from '../helpers/upload-helpers';

test.describe('Valid Upload', () => {
  test('successfully uploads a PDF file', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('test-doc', '.pdf');
    const content = createFileBuffer(1024, '%PDF-1.4 test content');

    await uploadFile(page, fileName, content, 'application/pdf');

    // Should redirect to details page with success message
    await page.waitForURL(/\/Outages\/Details\/\d+/);
    await expect(page.getByText(fileName)).toBeVisible();
  });

  test('successfully uploads a CSV file', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('test-data', '.csv');
    const content = createFileBuffer(256, 'col1,col2\nval1,val2\n');

    await uploadFile(page, fileName, content, 'text/csv');

    await page.waitForURL(/\/Outages\/Details\/\d+/);
    await expect(page.getByText(fileName)).toBeVisible();
  });

  test('uploaded file appears in documents table', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('doc-verify', '.txt');
    const content = createFileBuffer(128, 'verification content');

    await uploadFile(page, fileName, content, 'text/plain');

    await page.waitForURL(/\/Outages\/Details\/\d+/);

    // Scope assertion to the documents table to avoid strict-mode ambiguity
    const docsTable = page.locator('table').filter({ hasText: 'File' });
    await expect(docsTable.getByText(fileName)).toBeVisible();
  });
});
