using LegacyUploadDemo.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LegacyUploadDemo.Web.Pages;

public class IndexModel : PageModel
{
    private readonly ILegacyUploadService _uploadService;

    public IndexModel(ILegacyUploadService uploadService)
    {
        _uploadService = uploadService;
    }

    [BindProperty]
    public IFormFile? Upload { get; set; }

    public LegacyUploadSnapshot Snapshot { get; private set; } = new("", [], 0, "");
    public string StatusMessage { get; private set; } = string.Empty;

    public async Task OnGetAsync()
    {
        Snapshot = await _uploadService.GetSnapshotAsync();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        try
        {
            if (Upload is null)
            {
                StatusMessage = "Please choose a file before submitting the form.";
            }
            else
            {
                var savedPath = await _uploadService.SaveUploadAsync(Upload);
                StatusMessage = $"Upload saved to {savedPath}.";
            }
        }
        catch (Exception ex)
        {
            StatusMessage = ex.Message;
        }

        Snapshot = await _uploadService.GetSnapshotAsync();
        return Page();
    }
}
