#!/usr/bin/env bash
set -e

# Usage helper
NEW_VERSION=""
NO_COMMIT=false
NO_TAG=false
SKIP_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --no-commit)
      NO_COMMIT=true
      ;;
    --no-tag)
      NO_TAG=true
      ;;
    --skip-build)
      SKIP_BUILD=true
      ;;
    -h|--help)
      echo "Usage: ./scripts/bump_version.sh <version> [options]"
      echo ""
      echo "Options:"
      echo "  --no-commit    Do not create a git commit"
      echo "  --no-tag       Do not create a git tag"
      echo "  --skip-build   Skip rebuilding the web client distribution"
      echo "  -h, --help     Show this help message"
      echo ""
      echo "Example:"
      echo "  ./scripts/bump_version.sh 0.6.0"
      exit 0
      ;;
    -*)
      echo "Error: Unknown option '$arg'"
      echo "Usage: ./scripts/bump_version.sh <version> [--no-commit] [--no-tag] [--skip-build]"
      exit 1
      ;;
    *)
      if [ -z "$NEW_VERSION" ]; then
        NEW_VERSION="$arg"
      else
        echo "Error: Unexpected argument '$arg'"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$NEW_VERSION" ]; then
  echo "Error: Version number required."
  echo "Usage: ./scripts/bump_version.sh <version> [--no-commit] [--no-tag] [--skip-build]"
  echo "Example: ./scripts/bump_version.sh 0.6.0"
  exit 1
fi

# Strip leading 'v' if user accidentally passes v1.0.0
NEW_VERSION="${NEW_VERSION#v}"

# Find project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PUBSPEC_FILE="${ROOT_DIR}/pubspec.yaml"
APP_CONSTANTS="${ROOT_DIR}/lib/app_constants.dart"
CMAKE_FILE="${ROOT_DIR}/server/CMakeLists.txt"
VCPKG_JSON="${ROOT_DIR}/server/vcpkg.json"
DOCKER_COMPOSE="${ROOT_DIR}/server/docker-compose.yml"
WEB_DIR="${ROOT_DIR}/server/web"
PACKAGE_JSON="${WEB_DIR}/package.json"
PACKAGE_LOCK="${WEB_DIR}/package-lock.json"

echo "Bumping version to ${NEW_VERSION}..."

# 1. Update pubspec.yaml (version: X.Y.Z+build)
IFS='.' read -r MAJOR MINOR PATCH_EXTRA <<< "${NEW_VERSION}"
MAJOR="${MAJOR:-0}"
MINOR="${MINOR:-0}"
PATCH="${PATCH_EXTRA%%-*}"
PATCH="${PATCH:-0}"
BUILD_NUM=$((MAJOR * 10000 + MINOR * 100 + PATCH))
if [ "$BUILD_NUM" -eq 0 ]; then
  BUILD_NUM=1
fi

if [ -f "${PUBSPEC_FILE}" ]; then
  sed -i -E "s/^version: .*/version: ${NEW_VERSION}+${BUILD_NUM}/" "${PUBSPEC_FILE}"
  echo "✓ Updated ${PUBSPEC_FILE} -> ${NEW_VERSION}+${BUILD_NUM}"
fi

# 2. Update lib/app_constants.dart (const String appVersion = 'X.Y.Z';)
if [ -f "${APP_CONSTANTS}" ]; then
  sed -i -E "s/const String appVersion = ['\"][^'\"]+['\"];/const String appVersion = '${NEW_VERSION}';/" "${APP_CONSTANTS}"
  echo "✓ Updated ${APP_CONSTANTS} -> appVersion = '${NEW_VERSION}'"
fi

# 3. Update server/CMakeLists.txt
CMAKE_VERSION="${MAJOR}.${MINOR}.${PATCH}"
if [ -f "${CMAKE_FILE}" ]; then
  if grep -q "project(crowleys_cloud_server.*VERSION" "${CMAKE_FILE}"; then
    sed -i -E "s/(project\(crowleys_cloud_server.*VERSION )[0-9]+(\.[0-9]+)*/\1${CMAKE_VERSION}/" "${CMAKE_FILE}"
  elif grep -q "project(crowleys_cloud_server" "${CMAKE_FILE}"; then
    sed -i -E "s/project\(crowleys_cloud_server/project(crowleys_cloud_server VERSION ${CMAKE_VERSION}/" "${CMAKE_FILE}"
  fi
  echo "✓ Updated ${CMAKE_FILE} -> VERSION ${CMAKE_VERSION}"
fi

# 4. Update server/vcpkg.json ("version-string": "X.Y.Z")
if [ -f "${VCPKG_JSON}" ]; then
  sed -i -E "s/\"(version(-string|-semver)?)\": \"[^\"]+\"/\"\1\": \"${NEW_VERSION}\"/" "${VCPKG_JSON}"
  echo "✓ Updated ${VCPKG_JSON} -> version = '${NEW_VERSION}'"
fi

# 5. Update server/docker-compose.yml (image: ghcr.io/.../crowleys-cloud-server:vX.Y.Z)
if [ -f "${DOCKER_COMPOSE}" ]; then
  sed -i -E "s|(image:[[:space:]]*.*crowleys-cloud-server:v)[^[:space:]]+|\1${NEW_VERSION}|" "${DOCKER_COMPOSE}"
  echo "✓ Updated ${DOCKER_COMPOSE} -> image tag v${NEW_VERSION}"
fi

# 6. Update server/web/package.json & server/web/package-lock.json
if [ -d "${WEB_DIR}" ]; then
  if command -v npm >/dev/null 2>&1; then
    (cd "${WEB_DIR}" && npm version "${NEW_VERSION}" --no-git-tag-version --allow-same-version >/dev/null)
    echo "✓ Updated ${PACKAGE_JSON} and ${PACKAGE_LOCK} via npm -> ${NEW_VERSION}"
  else
    if [ -f "${PACKAGE_JSON}" ]; then
      sed -i -E "s/\"version\": \"[^\"]+\"/\"version\": \"${NEW_VERSION}\"/" "${PACKAGE_JSON}"
      echo "✓ Updated ${PACKAGE_JSON} -> ${NEW_VERSION}"
    fi
    if [ -f "${PACKAGE_LOCK}" ]; then
      if command -v node >/dev/null 2>&1; then
        node -e "
          const fs = require('fs');
          const p = '${PACKAGE_LOCK}';
          const d = JSON.parse(fs.readFileSync(p, 'utf8'));
          d.version = '${NEW_VERSION}';
          if (d.packages && d.packages['']) d.packages[''].version = '${NEW_VERSION}';
          fs.writeFileSync(p, JSON.stringify(d, null, 2) + '\n');
        "
      elif command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json
p = '${PACKAGE_LOCK}'
with open(p, 'r') as f:
    d = json.load(f)
d['version'] = '${NEW_VERSION}'
if 'packages' in d and '' in d['packages']:
    d['packages']['']['version'] = '${NEW_VERSION}'
with open(p, 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"
      else
        sed -i -E "0,/\"version\": \"[^\"]+\"/s//\"version\": \"${NEW_VERSION}\"/" "${PACKAGE_LOCK}"
      fi
      echo "✓ Updated ${PACKAGE_LOCK} -> ${NEW_VERSION}"
    fi
  fi
fi

# 7. Build web client distribution
if [ -d "${WEB_DIR}" ] && [ "$SKIP_BUILD" = false ]; then
  if command -v npm >/dev/null 2>&1; then
    echo "Building web client distribution..."
    (cd "${WEB_DIR}" && npm run check:i18n && npm run build)
    echo "✓ Web client built successfully"
  else
    echo "Warning: npm not found, skipping web client build."
  fi
fi

# 8. Git commit and tag
if [ "$NO_COMMIT" = false ]; then
  echo ""
  echo "Staging changed files..."
  STAGED_FILES=()
  for f in "${PUBSPEC_FILE}" "${APP_CONSTANTS}" "${CMAKE_FILE}" "${VCPKG_JSON}" "${DOCKER_COMPOSE}" "${PACKAGE_JSON}" "${PACKAGE_LOCK}" "${ROOT_DIR}/server/public"; do
    if [ -e "$f" ]; then
      STAGED_FILES+=("$f")
    fi
  done

  if [ ${#STAGED_FILES[@]} -gt 0 ]; then
    git add "${STAGED_FILES[@]}"
  fi

  if git diff --cached --quiet; then
    echo "No changes staged to commit."
  else
    git commit -m "chore(release): bump version to v${NEW_VERSION}"
    echo "✓ Created Git commit for v${NEW_VERSION}"
  fi

  if [ "$NO_TAG" = false ]; then
    if git rev-parse "v${NEW_VERSION}" >/dev/null 2>&1; then
      echo "Warning: Git tag v${NEW_VERSION} already exists. Skipping tag creation."
    else
      git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
      echo "✓ Created Git tag v${NEW_VERSION}"
    fi
  fi

  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")"
  echo ""
  echo "Successfully bumped version to v${NEW_VERSION}!"
  echo "To publish release to GitHub, run:"
  echo "  git push origin ${CURRENT_BRANCH} --tags"
else
  echo ""
  echo "Successfully updated version files to ${NEW_VERSION} (commit skipped)."
fi

