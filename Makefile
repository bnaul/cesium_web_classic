.PHONY: all clean test paths supervisord

# Supervisord only runs under Python 2, but that is no problem, even
# if everything else runs under Python 3.
SUPERVISORD=supervisord

SHELL = /bin/bash
.DEFAULT_GOAL := supervisord

db:
	@if [[ -n `rethinkdb --daemon --no-http-admin 2>&1 | grep "already in use"` ]]; then echo "[RethinkDB] is (probably) already running"; fi

celery:
	@if [[ -z `ps ax | grep -v grep | grep -v make | grep celery_tasks` ]]; then \
		PYTHONPATH="./cesium" celery worker -A cesium.celery_tasks -l info & \
	else \
		echo "[Celery] is already running"; \
	fi

clean:
	find . -name "*.so" | xargs rm -f

external/casperjs:
	@tools/casper_install.sh

test: external/casperjs db celery
	echo -e "testing:\n    disable_auth: 1\n    test_db: 1" > "cesium-_test_.yaml"
	echo -e "docker:\n    enabled: 1\n" >> "cesium-_test_.yaml"
	@PYTHONPATH="." tools/casper_tests.py
	nosetests -v cesium_app

test_no_docker: external/casperjs db celery
	echo -e "testing:\n    disable_auth: 1\n    test_db: 1" > "cesium-_test_.yaml"
	echo -e "docker:\n    enabled: 0\n" >> "cesium-_test_.yaml"
	@PYTHONPATH="." tools/casper_tests.py
	nosetests -v cesium_app

install:
	pip install -r requirements.txt

paths:
	mkdir -p log run tmp
	mkdir -p log/sv_child
	mkdir -p ~/.local/cesium/logs

log: paths
	./tools/watch_logs.py

supervisord: paths
	$(SUPERVISORD) -c supervisord.conf
