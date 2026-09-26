return {
  "selimacerbas/markdown-preview.nvim",
  dependencies = { "selimacerbas/live-server.nvim" },
  cmd = { "MarkdownPreview", "MarkdownPreviewRefresh", "MarkdownPreviewStop" },
  ft = { "markdown" },
  keys = {
    {
      "<leader>mr",
      "<cmd>MarkdownPreview<cr>",
      desc = "Toggle Markdown Preview"
    }
  },
  opts = {
    host = "0.0.0.0",
    open_browser = false,
    hooks = {
      on_start = function(url)
        local devbox_url = url:gsub("^(https?://)[^:/]+", "%1devbox")
        vim.fn.setreg("+", devbox_url)
        vim.fn.setreg('"', devbox_url)
        vim.notify("Markdown preview URL copied to clipboard", vim.log.levels.INFO, {
          timeout = 8000,
        })
      end,
    },
  },
}
