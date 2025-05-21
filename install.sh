#!/usr/bin/env bash
set -eu

function install_dotfiles() {
  local source="${1:-}"
  local target="${2:-}"
  if test ! -e "${source:-}"; then return 0; fi

  while read -r file; do

      relative_file_path="${file#"${source}"/}"
      file_name="${relative_file_path##*/}"
      target_file="${target}/${relative_file_path}"
      target_dir="${target_file%/*}"

      if test ! -d "${target_dir}"; then
          mkdir -p "${target_dir}"
      fi

    case "$file_name" in
        ".bashrc"|".bash_profile"|".zshrc"|".zprofile"|".kshrc"|".profile"|"config.fish")
        echo "Your $file_name is being virtually loaded into the existing host $target_file";
        if test "$file_name" != "config.fish"; then {
            local check_str="if test -e '$file'; then source '$file'; fi";
        } else {
            local check_str="if test -e '$file'; source '$file'; end";
        } fi
        if ! grep -q "$check_str" "$target_file"; then {
            printf '%s\n' "$check_str" >> "$target_file";
        } fi
        continue; # End this loop
        ;;
        ".gitconfig")
        echo "Your $file_name is being merged with the existing host $target_file";
        local check_str="# dotsh merged";
        if ! grep -q "$check_str" "$target_file" 2>/dev/null; then {
            # The native `[include.path]` doesn't seem to work as expected, so yeah...
            printf '\n%s\n' \
            "$check_str" \
            "$(< "$file")" \
            "$check_str" >> "$target_file";
        } fi
        continue; # End this loop
        ;;
    esac

      printf 'Installing dotfiles symlink %s\n' "${target_file}"
      ln -sf "${file}" "${target_file}"

  done < <(find "${source}" -type f)
}

current_dir="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

install_dotfiles "${current_dir}/home_files" "${HOME}"
install_dotfiles "${current_dir}/workspace_repo" "${GITPOD_REPO_ROOT}"