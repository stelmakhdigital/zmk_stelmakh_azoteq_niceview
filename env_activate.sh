#!/bin/bash
source venv/bin/activate
source zmk/zephyr/zephyr-env.sh
exec "$@"
