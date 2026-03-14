#!/bin/bash
set -euo pipefail

pkill -x SlowTVController 2>/dev/null || true
bash build.sh
open build/SlowTVController.app
