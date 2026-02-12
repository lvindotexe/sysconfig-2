{ pkgs, lib, ... }:

{
  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        viAlias = false;
        vimAlias = true;

        lineNumberMode = "relNumber";

        autocomplete = {
          enableSharedCmpSources = true;
          blink-cmp = {
            enable = true;
            "friendly-snippets".enable = true;
          };
        };

        extraPackages = with pkgs; [
          eslint_d
        ];

        lsp = {
          enable = true;
          lspconfig.enable = true;
        };

        binds.whichKey.enable = true;

        augroups = [
          {
            name = "NvfLspKeymaps";
            clear = true;
          }
          {
            name = "NvfSessions";
            clear = true;
          }
        ];

        autocmds = [
          {
            event = [ "LspAttach" ];
            group = "NvfLspKeymaps";
            desc = "Set buffer-local LSP keymaps";
            callback = lib.generators.mkLuaInline ''
              function(args)
                local bufnr = args.buf
                local base = { buffer = bufnr, silent = true }

                local function map(mode, lhs, rhs, desc)
                  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", base, { desc = desc }))
                end

                map("n", "gd", vim.lsp.buf.definition, "Go to definition")
                map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
                map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
                map("n", "gr", vim.lsp.buf.references, "References")
                map("n", "K", vim.lsp.buf.hover, "Hover")
                map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
                map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
                map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
                map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
              end
            '';
          }
          {
            event = [ "User" ];
            pattern = [ "SessionLoadPost" ];
            group = "NvfSessions";
            desc = "Re-run FileType after session load";
            callback = lib.generators.mkLuaInline ''
              function()
                vim.schedule(function()
                  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_loaded(buf) then
                      local name = vim.api.nvim_buf_get_name(buf)
                      if name ~= "" and vim.bo[buf].buftype == "" then
                        vim.api.nvim_buf_call(buf, function()
                          if vim.bo.filetype == "" then
                            vim.cmd("silent! filetype detect")
                          end
                          vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
                        end)
                      end
                    end
                  end
                end)
              end
            '';
          }
        ];

        maps.normal."<leader>b" = {
          action = "<cmd>Neotree toggle<cr>";
          desc = "Toggle file tree";
          silent = true;
        };

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        diagnostics = {
          enable = true;
          config = {
            signs = true;
            underline = true;
            update_in_insert = true;
            virtual_text = true;
            virtual_lines = false;
          };

          nvim-lint = {
            enable = true;
            lint_after_save = true;

            linters_by_ft = {
              javascript      = [ "eslint_d" ];
              javascriptreact = [ "eslint_d" ];
              typescript      = [ "eslint_d" ];
              typescriptreact = [ "eslint_d" ];
            };

            linters.eslint_d.required_files = [
              "eslint.config.js"
              ".eslintrc"
              ".eslintrc.js"
              ".eslintrc.cjs"
              ".eslintrc.json"
            ];
          };
        };

        languages = {
          go = {
            enable = true;
            lsp.enable = true;
          };
          ts = {
            enable = true;
            lsp.enable = true;
          };
          nix = {
            enable = true;
            lsp.enable = true;
          };
        };

        telescope.enable = true;

        session."nvim-session-manager" = {
          enable = true;
          setupOpts.autoload_mode = "CurrentDir";
        };

        filetree."neo-tree" = {
          enable = true;
          setupOpts = {
            enable_git_status = true;
            enable_diagnostics = true;
            filesystem.filtered_items = {
              visible = true;
              hide_dotfiles = false;
              hide_gitignored = false;
            };
          };
        };

        git = {
          enable = true;
          gitsigns.enable = true;
        };

        utility."diffview-nvim".enable = true;
      };
    };
  };
}
