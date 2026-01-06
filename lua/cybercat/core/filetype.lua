vim.cmd("au BufRead,BufNewFile *.tf setfiletype terraform")
vim.cmd([[
  autocmd BufRead,BufNewFile *.mdx set filetype=markdown.mdx
]])
vim.cmd([[
  autocmd BufRead,BufNewFile *.html set filetype=html
]])
vim.cmd([[
  autocmd BufRead,BufNewFile *.hbs set filetype=handlebars
]])
