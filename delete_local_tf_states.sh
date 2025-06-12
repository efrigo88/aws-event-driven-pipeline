# Find and delete all .terraform directories
find . -type d -name ".terraform" -exec rm -rf {} +
find . -type d -name "terraform.tfstate.d" -exec rm -rf {} +

# Find and delete specific terraform state files and directories
find . -type f \( \
    -name ".terraform.lock.hcl" \
    -o -name ".terraform.tfstate.lock.info" \
    -o -name "terraform.tfstate.backup" \
    -o -name "terraform.tfstate" \
    -o -name "myplan" \
\) -exec rm -f {} +