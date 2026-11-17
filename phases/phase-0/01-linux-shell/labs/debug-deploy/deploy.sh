set -euo pipefail

APP_ENV=staging
source config/settings.env
mkdir -p out
./scripts/render.sh
echo "deploy finished for $APP_ENV ($APP_NAME)"
