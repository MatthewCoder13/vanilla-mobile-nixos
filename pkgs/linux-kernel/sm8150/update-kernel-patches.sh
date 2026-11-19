#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash nixfmt
set -eu -o pipefail

if (( $# != 3 )); then
    echo "Usage: $(basename "$0") <path to sm8150 repo> <Linux tag. Ex: v7.0> <sm8150 tag/commit. Ex: v7.0.0-sm8150>"
    exit 1
fi

kernel_repo="$1"
linux_ref="refs/tags/$2"
sm8150_ref="$3"
patches_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/kernel-patches
patches_list_file="$patches_dir/default.nix"

pushd "$kernel_repo"

git fetch

if ! git rev-parse --verify --quiet "$sm8150_ref" > /dev/null; then
    >&2 echo "$sm8150_ref doesn't exist."
    exit 1
fi

if ! git show-ref --verify --quiet "$linux_ref"; then
    >&2 echo "Linux tag, $linux_ref doesn't exist. Searching for matching release commit."
    linux_ref=$(git log -n 1 --pretty=format:"%H" --grep "^Linux ${linux_ref#refs/tags/v}$" "$sm8150_ref~1000..$sm8150_ref")
    if [[ -z "$linux_ref" ]]; then
	>&2 echo "Linux commit not found."
	exit 1
    fi
    echo "Found matching Linux release commit: $linux_ref"
fi

rm -f "$patches_dir"/*.patch

echo "[" > "$patches_list_file"
git format-patch --no-merges "$linux_ref..$sm8150_ref" -o "$patches_dir" |
while read -r patch_path; do
    # Filter out patches with no changes. These are usually cover letters.
    if ! grep -q "diff --git a/" "$patch_path"; then
	echo "# Patch makes no changes." >> "$patches_list_file"
	p="#"
    else
	p=""
    fi
    echo "$p {" >> "$patches_list_file"
    echo "$p name = \"$(basename -s .patch "$patch_path")\";" >> "$patches_list_file"
    echo "$p patch = ./$(basename "$patch_path");" >> "$patches_list_file"
    echo "$p }" >> "$patches_list_file"
done
echo "]" >> "$patches_list_file"
nixfmt "$patches_list_file"

popd
