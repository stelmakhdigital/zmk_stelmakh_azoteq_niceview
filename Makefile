.ONESHELL:
.EXPORT_ALL_VARIABLES:
.PHONY: build clean source freeze start all check-logs

BASE_DIR := ${PWD}
ZMK_APP_DIR ?= zmk/app
ZEPHYR_DIR ?= ${PWD}/zephyr
FIRMWARE_DIR ?= firmware
DZMK_CONFIG="${PWD}/config"
DSHIELD_LEFT ?= stelmakh_left
DSHIELD_RIGHT ?= stelmakh_right
MAIN_BOARD ?= nice_nano_v2

export BOARD_ROOT := ${PWD}

default: help
help: Makefile
	@echo "\n Choose a command run"
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'

## * make freeze - зафиксировать зависимости PIP в requirements.txt;
freeze:
	. venv/bin/activate && \
	pip freeze > ${BASE_DIR}/requirements.txt

_build_l:
	west build -d build/left -s ${ZMK_APP_DIR} -b ${MAIN_BOARD} -S zmk-usb-logging -- \
	-DSHIELD="stelmakh_left nice_view" \
	-DZMK_CONFIG=${DZMK_CONFIG}
	mkdir -p ${FIRMWARE_DIR}
	cp build/left/zephyr/zmk.uf2 ${FIRMWARE_DIR}/stelmakh_left_${MAIN_BOARD}.uf2

_build_r:
	west build -d build/right -s ${ZMK_APP_DIR} -b ${MAIN_BOARD} -S zmk-usb-logging -- \
	-DSHIELD="stelmakh_right nice_view" \
	-DZMK_CONFIG=${DZMK_CONFIG}
	mkdir -p ${FIRMWARE_DIR}
	cp build/right/zephyr/zmk.uf2 ${FIRMWARE_DIR}/stelmakh_right_${MAIN_BOARD}.uf2

_build_reset:
	west build -d build/reset -s ${ZMK_APP_DIR} -b ${MAIN_BOARD} -- -DSHIELD="settings_reset" -DZMK_CONFIG=${DZMK_CONFIG}
	mkdir -p ${FIRMWARE_DIR}
	cp build/reset/zephyr/zmk.uf2 ${FIRMWARE_DIR}/stelmakh_reset_${MAIN_BOARD}.uf2

_clear_all:
	rm -rf .west build ${FIRMWARE_DIR} zephyr/.cache/ zmk/.cache/ ~/Library/Caches/zephyr/
	find . -name "__pycache__" -type d -exec rm -rf {} +

_clear:
	rm -rf .west build ${FIRMWARE_DIR}

## * make all - build all firmwares (left, right, reset);
all: _clear_all _env _build_l _build_r _build_reset

_first_init:
	brew update && \
	brew install --cask gcc-arm-embedded && \
	brew install cmake ninja gperf python3 ccache qemu dtc wget libmagic && \
	python3 -m venv venv
 
_install_west:
	. venv/bin/activate && \
	pip install --upgrade pip && \
	pip install pyelftools && \
	pip install west && \
	git clone https://github.com/zmkfirmware/zmk.git && \
	cd zmk && \
	west init -l app && \
	west update && \
	pip install -r ./zephyr/scripts/requirements-extras.txt && \
	west zephyr-export && \
	west list
	cd ..

_init_env_values:
	chmod +x setup_env.sh && \
	chmod +x env_activate.sh && \
	./setup_env.sh

_env:
	./env_activate.sh

## * make start - initial project setup (venv, west, zephyr env);
start: _first_init _install_west _init_env_values

## * make check-logs - connect to the keyboard logs via screen;
check-logs:
	@DEV=$$(ls /dev/tty.usbmodem* | head -n1); \
	if [ -z "$$DEV" ]; then \
		echo "No /dev/tty.usbmodem* device found!"; \
		exit 1; \
	fi; \
	echo "Connecting to $$DEV ..."; \
	screen $$DEV 115200
