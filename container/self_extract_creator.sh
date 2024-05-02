#!/usr/bin/env bash
# <!---------------------------
# Name: adm_unix_scripts
# File: docker_self_extract_creator
# -----------------------------
# Author: lpi-code <loic.code@piernas.fr>
# Data:   4/29/2024, 2:55:46 PM
# ---------------------------->
set -euo pipefail

while getopts "i:o:" opt; do
  case ${opt} in
    i )
      docker_image=$OPTARG
      ;;
    o )
      output_file=$OPTARG
      ;;
    \? )
      echo "Usage: $0 -i input_file -o output_file"
      exit 1
      ;;
  esac
done

if [ -z {docker_image:+x} ] && [ -z {output_file:+x} ]; then
  echo "Usage: $0 -i docker_image -o output_file"
  exit 1
fi

template_script=$(cat <<'EOF'
#!/usr/bin/env bash
# Inspired by: https://gist.github.com/ChrisCarini/d3e97c4bc7878524fa11#file-embeddedpayload-sh
set -euo pipefail

SCRIPT_DIR="$(cd -P "$( dirname "${BASH_SOURCE[0]}" )" ; pwd)"
SKIP=$(awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0)


# Extract
echo "Extracting install ... "
tail -n +${SKIP} $0 | unxz -T<PROC_NB>  | docker load -t <DOCKER_IMAGE>

exit 0
# NOTE: Don't place any newline characters after the last line below.
__TARFILE_FOLLOWS__
EOF
)

# Replace <PROC_NB> with the number of processors
template_script=$(echo "$template_script" | sed "s/<PROC_NB>/$(nproc)/g")

# Create the self-extracting script
echo "$template_script" > "$output_file"
docker save "$docker_image" | xz -9 -T$(nproc) >> "$output_file"