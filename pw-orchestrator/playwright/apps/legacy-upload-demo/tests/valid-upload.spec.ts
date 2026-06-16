import { test, expect } from '@playwright/test';
import { uniqueFilename, createFileBuffer, uploadFile } from '../../../helpers/test-utils';
import { navigateToUploadPage, detailsPagePattern } from '../app-helpers';

test.describe('Valid Upload', () => {
  test('successfully uploads a PDF file', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('test-doc', '.pdf');
    const content = createFileBuffer(1024, '%PDF-1.4 test content');

    await uploadFile(page, fileName, content, { mimeType: 'application/pdf' });

    await page.waitForURL(detailsPagePattern());
    const docsTable = page.locator('table').filter({ hasText: 'File' });
    await expect(docsTable.getByRole('cell', { name: fileName })).toBeVisible();
  });

  test('successfully uploads a CSV file', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('test-data', '.csv');
    const content = createFileBuffer(256, 'col1,col2\nval1,val2\n');

    await uploadFile(page, fileName, content, { mimeType: 'text/csv' });

    await page.waitForURL(detailsPagePattern());
    const docsTable = page.locator('table').filter({ hasText: 'File' });
    await expect(docsTable.getByRole('cell', { name: fileName })).toBeVisible();
  });

  test('uploaded file appears in documents table', async ({ page }) => {
    await navigateToUploadPage(page);

    const fileName = uniqueFilename('doc-verify', '.txt');
    const content = createFileBuffer(128, 'verification content');

    await uploadFile(page, fileName, content, { mimeType: 'text/plain' });

    await page.waitForURL(detailsPagePattern());
    const docsTable = page.locator('table').filter({ hasText: 'File' });
    await expect(docsTable.getByText(fileName)).toBeVisible();
  });
});
