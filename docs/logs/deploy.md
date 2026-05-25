# Deploy Logs

Running with gitlab-runner 18.9.0 (07e534ba)
on diaverse-runner ka7UuXPBJ, system ID: s_eac633f20f28
Preparing the "shell" executor
00:00
Using Shell (bash) executor...
Preparing environment
00:00
Running on msk-1-vm-r93x...
Getting source from Git repository
00:01
Gitaly correlation ID: 01KN7SBVM2C3D0377HVFFABDFY
Fetching changes with git depth set to 20...
Reinitialized existing Git repository in /root/builds/ka7UuXPBJ/0/diaverse/diaverse-api/.git/
Checking out 5180fd2d as detached HEAD (ref is dev)...
Skipping Git submodules setup
Executing "step_script" stage of the job script
00:17
$ echo "Deploy commit: $CI_COMMIT_SHA"
Deploy commit: 5180fd2d6e23d580d6fb3e5afdf35134d54c7ef5
$ mkdir -p "$APP_DIR" "$CONFIG_DIR"
$ rsync -a --delete --exclude ".git" --exclude ".gitlab-ci.yml" --exclude ".github" --exclude ".idea" --exclude ".venv" --exclude "**pycache**" --exclude ".pytest_cache" "$CI_PROJECT_DIR"/ "$APP_DIR"/
$ install -m 644 "$APP_DIR/pyproject.toml" "$CONFIG_DIR/pyproject.toml"
$ install -m 644 "$APP_DIR/poetry.lock" "$CONFIG_DIR/poetry.lock"
$ install -m 644 "$APP_DIR/alembic.ini" "$CONFIG_DIR/alembic.ini"
$ cd /home && make build
docker-compose -f config/docker-compose.yml --profile build build app-image
Image diaverse-app:local Building
#1 [internal] load local bake definitions
#1 reading from stdin 490B done
#1 DONE 0.0s
#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 710B done
#2 DONE 0.0s
#3 [internal] load metadata for docker.io/library/python:3.12-slim
#3 DONE 0.0s
#4 [internal] load .dockerignore
#4 transferring context: 2B done
#4 DONE 0.0s
#5 [1/5] FROM docker.io/library/python:3.12-slim@sha256:3d5ed973e45820f5ba5e46bd065bd88b3a504ff0724d85980dcd05eab361fcf4
#5 resolve docker.io/library/python:3.12-slim@sha256:3d5ed973e45820f5ba5e46bd065bd88b3a504ff0724d85980dcd05eab361fcf4 0.0s done
#5 DONE 0.0s
#6 [internal] load build context
#6 transferring context: 352.86kB done
#6 DONE 0.0s
#7 [2/5] RUN pip install "poetry==1.8.2"
#7 CACHED
#8 [3/5] WORKDIR /app
#8 CACHED
#9 [4/5] COPY poetry.lock pyproject.toml alembic.ini /app/
#9 CACHED
#10 [5/5] RUN poetry config virtualenvs.create false && poetry install --no-interaction --no-ansi --no-root
#10 CACHED
#11 exporting to image
#11 exporting layers done
#11 exporting manifest sha256:04b6ab20f5ba65728584fae67da320b52f47cc71205dc903924646bc58780fbc done
#11 exporting config sha256:caec5b442fcd93f37aace5375803b310513f2771ca255a6ca39a06d138300415 done
#11 exporting attestation manifest sha256:77864d73d00579d924b65acefca09d6f9e8ddc6a4cd06ed58298728b55e63d2a 0.0s done
#11 exporting manifest list sha256:43b490857d84b934627fe934e3e0ec1681536b2c69691b7ab557da5b37e1f0e0
#11 exporting manifest list sha256:43b490857d84b934627fe934e3e0ec1681536b2c69691b7ab557da5b37e1f0e0 0.0s done
#11 naming to docker.io/library/diaverse-app:local done
#11 unpacking to docker.io/library/diaverse-app:local done
#11 DONE 0.1s
#12 resolving provenance for metadata file
#12 DONE 0.0s
Image diaverse-app:local Built
$ cd /home && make migrate
docker-compose -f config/docker-compose.yml run --rm --no-deps migrate
time="2026-04-02T19:05:20Z" level=warning msg="Found orphan containers ([diaverse-postgres-exporter-1 diaverse-prometheus-1 diaverse-grafana-1 diaverse-redis-exporter-1 diaverse-node-exporter-1]) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up."
Container diaverse-migrate-run-847d2878fc12 Creating
Container diaverse-migrate-run-847d2878fc12 Created
INFO [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO [alembic.runtime.migration] Will assume transactional DDL.
$ cd /home && make deploy
docker-compose -f config/docker-compose.yml up -d --no-deps --force-recreate api scheduler
time="2026-04-02T19:05:26Z" level=warning msg="Found orphan containers ([diaverse-postgres-exporter-1 diaverse-prometheus-1 diaverse-grafana-1 diaverse-redis-exporter-1 diaverse-node-exporter-1]) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up."
Container diaverse-api-1 Recreate
Container diaverse-scheduler-1 Recreate
Container diaverse-api-1 Recreated
Container diaverse-scheduler-1 Recreated
Container diaverse-scheduler-1 Starting
Container diaverse-api-1 Starting
Container diaverse-scheduler-1 Started
Container diaverse-api-1 Started
Cleaning up project directory and file based variables
00:00
Job succeeded
