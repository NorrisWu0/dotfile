return {
  "selimacerbas/markdown-preview.nvim",
  dependencies = { "selimacerbas/live-server.nvim" },
  cmd = { "MarkdownPreview", "MarkdownPreviewRefresh", "MarkdownPreviewStop" },
  ft = { "markdown" },
  opts = {
    host = "0.0.0.0",
    open_browser = false,
    hooks = {
      on_start = function(url)
        local devbox_url = url:gsub("^(https?://)[^:/]+", "%1devbox")
        vim.notify(devbox_url, vim.log.levels.INFO)
      end,
    },
  },
}
