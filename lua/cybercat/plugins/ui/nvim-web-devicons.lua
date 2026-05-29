return {
  "nvim-tree/nvim-web-devicons",
  config = function()
    require("nvim-web-devicons").set_icon({
      gql = {
        icon = "",
        color = "#e535ab",
        cterm_color = "199",
        name = "GraphQL",
      },
      wgsl = {
        icon = "󰬲",
        color = "#ff6a00",
        cterm_color = "208",
        name = "Wgsl",
      },
    })
  end,
}
