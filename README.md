# InferGauge

<p align="center">
  <img src="demo/infergauge-dashboard.gif" width="760"
       alt="InferGauge live dashboard during a stress test: users ramp to 900, the saturation knee appears at 380, SLAs fail, quality drops from 97% to 71%">
</p>
<p align="center"><em>A stress test running live — the saturation knee at 380 users, SLAs failing at 800, quality collapsing under load.</em></p>

<p align="center"><img src="demo/quickstart.svg" alt="InferGauge quickstart: pip install, init, run" width="720"></p>

```bash
pip install infergauge && infergauge init -y && infergauge run
```

> Source-available under [BSL 1.1](LICENSE) — free to read, modify and run
> (including in production and CI); not to resell as a hosted service.
> Converts to Apache 2.0 in 2030. See [COMMERCIAL.md](docs/business/COMMERCIAL.md).

**See it without installing:**
- [`demo/infergauge-dashboard.mp4`](demo/infergauge-dashboard.mp4) — 24-second video of the
  dashboard during a live stress test (also as a GIF, above)
- [`demo/infergauge-demo.html`](demo/infergauge-demo.html) — self-playing 100-second product
  tour with narration, runs in any browser
- [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md) — shot list for recording your own
- [`demo/render_video.py`](demo/render_video.py) — regenerates the video/GIF

Three commands. No API key needed. Your browser opens to a live dashboard while
InferGauge finds your AI application's breaking point.

**AI performance testing with a live dashboard.** Load, stress, spike, and
endurance tests for AI applications — real-time visibility into latency
(E2E / TTFT / inter-token), throughput, token usage, cost, goodput, and SLA
validation. CLI-first for CI/CD; the dashboard is the lens.

## Install

**Download and run (recommended)** - a single native binary, no Python needed.
Grab the file for your OS from the [latest release](https://github.com/Nexus-InferGauge/infergauge-releases/releases/latest), then:

```bash
./infergauge init -y && ./infergauge run     # dashboard opens at localhost:8710
```

Binaries are compiled to native code (Nuitka) and code-signed for Windows and
macOS, so there is no interpreter to install and no OS trust warning.

**Homebrew (macOS / Linux)**

```bash
brew install Nexus-InferGauge/infergauge/infergauge
```

**pip - for CI/CD pipelines.** Load tests belong in your deploy gate; the
wheel is the right channel for that:

```bash
pip install infergauge
infergauge run ci.yaml --headless --report out/   # exit code 0/1 by SLA
```

See `ci/github-actions.yml` for a ready-made workflow. Installing from the
downloaded wheel file works the same way: `pip install infergauge-0.7.0-py3-none-any.whl`.


## Web console (accounts, teams, licensing)

```bash
infergauge serve                    # http://localhost:8720
```

Team members create an account, sign in, configure a test, and watch it run —
no CLI, no YAML. Every tier limit is enforced on the server, so the browser
cannot bypass it.

```bash
# operator: create the signing secret once, keep it in your secret manager
export INFERGAUGE_FERNET_KEY=$(infergauge license keygen)
infergauge serve                    # the console can now validate license tokens

# mint a customer/deployment token
infergauge license generate --tier team --key-id acme-prod --expires-at 2027-01-01T00:00:00Z
```

Users paste that token into **License** in the console, or set
`INFERGAUGE_API_KEY` (alias `INFERGAUGE_LICENSE_KEY`) plus `INFERGAUGE_FERNET_KEY`
for the CLI. Check the effective tier any time with `infergauge license status`.

See [`docs/LICENSING.md`](docs/LICENSING.md) for the tier table and the hosted
deployment note.

## macOS install

The wheel is platform-independent (`py3-none-any`), so install failures on macOS are
always environment issues. This one sequence avoids all of them:

```bash
python3 --version                 # must be 3.10+ (macOS ships 3.9 - see below)
python3 -m venv ~/infergauge-env
source ~/infergauge-env/bin/activate
pip install ~/Downloads/infergauge-0.7.0-py3-none-any.whl
infergauge init -y && infergauge run
```

Re-activate later with `source ~/infergauge-env/bin/activate`.

| Error you saw | Cause | Fix |
|---|---|---|
| `requires a different Python: 3.9.6 not in '>=3.10'` | macOS system Python is 3.9 | `brew install python@3.12`, then use `python3.12 -m venv ...` (or install from python.org) |
| `error: externally-managed-environment` | Homebrew Python blocks global installs (PEP 668) | Use the venv above — do **not** use `--break-system-packages` |
| `pip: command not found` | macOS has no `pip` alias | Use `python3 -m pip` |
| `is not a valid wheel filename` | Safari renamed or unzipped the file | Re-download with "Download Linked File As…", keep the `.whl` name |
| `no such file or directory` | wrong path | `cd ~/Downloads` first, or drag the file into Terminal to paste its path |

## Quick start

```bash
infergauge init                 # interactive setup -> infergauge.yaml
infergauge run                  # run it; live dashboard opens automatically
```

Pick the **Simulator** provider during init to try InferGauge instantly with no
API key — it behaves like a real endpoint, degrading past a saturation point
and rate-limiting under quota pressure, so every chart and insight lights up.

Override anything from the command line:

```bash
infergauge run --users 500 --type load
infergauge run --users 1000 --type stress --duration 300
infergauge run prod-test.yaml --model gpt-4o-mini
```

Revisit past results any time:

```bash
infergauge runs                 # list saved runs (score + SLA verdict)
infergauge dashboard            # replay the latest run in the dashboard
infergauge dashboard --run 20260717-011813
infergauge compare              # delta table: last two runs
infergauge run --baseline latest --max-regression-pct 15   # CI regression gate
```

## Quality under load

InferGauge can sample responses during a load test and run deterministic quality
checks (valid JSON, required fields, contains/regex, length bounds) - measuring
whether answer quality degrades as concurrency rises. Failed quality samples
count against goodput, the `min_quality_pct` SLA gates CI, and the report gets
a quality-vs-load chart. Configure it with:

```yaml
quality:
  sample_rate: 0.25
  checks:
    - type: valid_json
    - type: json_required_fields
      value: answer, confidence
    - type: contains
      value: order
sla:
  min_quality_pct: 92
```

## Providers

| Provider | `provider.kind` | Notes |
|---|---|---|
| Simulator | `simulator` | no key needed; tunable saturation & rate limits |
| OpenAI | `openai-compatible` | `base_url: https://api.openai.com/v1` |
| Anthropic Claude | `anthropic` | native Messages API with streaming TTFT/ITL |
| Azure OpenAI | `openai-compatible` | point `base_url` at your resource |
| Google Gemini | `openai-compatible` | Gemini's OpenAI-compatible endpoint |
| Local (Ollama / vLLM / LM Studio) | `openai-compatible` | e.g. `http://localhost:11434/v1` |

`infergauge init` scaffolds the right block for each of these.

## CI/CD — run on your org's infrastructure

Run InferGauge from your CI runners instead of laptops: runners sit close to the
app (stable network, no Wi-Fi noise), have consistent hardware, and turn every
merge into a performance checkpoint.

```bash
# PR pipeline: gate against the main-branch baseline
infergauge run ci-test.yaml --headless \
  --baseline main --max-regression-pct 15 \
  --junit results/junit.xml --report results/
echo $?   # 0 = SLAs met & no regression · 1 = breach or regression

# main-branch pipeline: refresh the baseline after merge
infergauge run ci-test.yaml --headless --save-baseline main
```

**Ready-made templates** (baseline caching, native test reports, artifacts):
`.github/workflows/perf-gate.yml` (GitHub Actions), `ci/gitlab-ci.yml`,
`ci/Jenkinsfile`, `ci/azure-pipelines.yml`.

**CI features:**
- `--junit FILE` — SLA checks + regression checks as JUnit test cases, rendered
  natively by Jenkins, GitLab MR widgets, and Azure DevOps Tests tab
- `--save-baseline NAME` / `--baseline NAME` — named baselines in
  `.infergauge/baselines/`; persist them across ephemeral runners with your CI
  cache (all four templates do this)
- GitHub step summary — when `$GITHUB_STEP_SUMMARY` is set, a markdown scorecard
  is posted to the job summary automatically
- `INFERGAUGE_*` env overrides — one committed config, many environments:
  `INFERGAUGE_BASE_URL`, `INFERGAUGE_MODEL`, `INFERGAUGE_USERS`, `INFERGAUGE_DURATION_S`,
  `INFERGAUGE_TEST_TYPE`, `INFERGAUGE_PROVIDER`, `INFERGAUGE_API_KEY_ENV` — so staging
  and prod pipelines share a config and differ only in variables
- API keys come from your CI secret store via `api_key_env` — never in the repo
- No implicit network calls: `--headless` and CI environments (`CI` set) skip
  the update-nag check on their own; set `INFERGAUGE_NO_UPDATE_CHECK=1`
  anywhere else you want it off too

## What the dashboard shows

- **Performance score** (0-100) with an explainable component breakdown
  (latency 30 / errors 25 / goodput 20 / token perf 15 / cost 10). A component is
  graded **only when the config defines the SLA it needs** — InferGauge will not
  invent a threshold you didn't choose and grade you against it. Ungraded
  components show `no SLA`, are excluded from the average, and the score is
  labelled **provisional** with the exact settings to add:

  ```
  score      97/100 (healthy)  PROVISIONAL - only 45% of weight graded
             ungraded: set sla.p95_latency_ms
             ungraded: set sla.itl_p95_ms
             ungraded: set sla.max_cost_usd
  ```
- **KPI cards**: avg/p95/p99 latency, TTFT, inter-token latency; active users,
  in-flight, error rate, **goodput** (% of requests meeting *all* SLOs);
  token in/out and tokens/sec; spend, cost/request, projected monthly
- **Latency & load timeline** with SLA threshold line and event markers for
  every manual intervention (results stay honest)
- **Saturation curve** — live p95-vs-users scatter; the knee is your ceiling
- **SLA validation panel**, **error taxonomy** (429 / 5xx / timeout /
  connection + retries), and **rule-based insights** (saturation knee,
  rate limiting, TTFT-vs-ITL bottleneck diagnosis, drift at steady load,
  quality degradation under load, unreachable-endpoint and bad-model
  diagnostics, small-sample percentile warnings, cost pressure)
- **Statistical honesty**: p95/p99 are flagged with `*` until there are ~100
  samples, because a percentile from 8 requests is just the slowest request
- **Live controls**: adjust users or stop the test mid-run
- **Exports**: HTML report + JSON

## Accounts and the web console

InferGauge can run entirely standalone. Teams that want shared history, plan
management and a usage dashboard can also run the console:

```bash
infergauge serve                      # http://localhost:8720
```

**The console never executes tests.** It authorises runs, meters your plan and
stores results. Every test executes on your own machine, with your own API
keys, through the CLI acting as a local agent:

```
   browser (console)                     your machine (agent)
   ─────────────────                     ────────────────────
   sign up / sign in                     infergauge login --server <console>
   build a config      ──── yaml ───▶    infergauge run infergauge.yaml --sync
   plan + quota check  ◀─── authorise ──
   watch live progress ◀─── progress ───  (test runs here, against your endpoint)
   history + reports   ◀─── summary ────
```

### Building a test in the console

The **New test** tab is a form that produces a ready-to-run config. It checks
the test against your plan *before* generating anything, so you find out about
a limit here rather than halfway through a run.

- **Provider presets** for OpenAI, Anthropic, Groq, Together AI, Fireworks AI
  and Ollama fill in the right base URL, a sensible model and the conventional
  API-key variable name. Anything else that speaks the OpenAI API works via
  *Other OpenAI-compatible*.
- **Prompt** is yours to set. Token counts, TTFT and cost all scale with the
  prompt, so a generic one gives you generic numbers — paste the prompt your
  application actually sends. Multi-line is fine. Left blank, a sample is used.
- **Download infergauge.yaml** writes the config straight to disk (or copy it
  and save it yourself). The file is generated in your browser: the config names
  an environment variable, never the key itself.

Two SLA thresholds are not on the form — `itl_p95_ms` and `max_cost_usd`. Add
them by hand if you want a fully graded score rather than a provisional one
(see [Config reference](#config-reference)).

Why this shape:

- **Honest measurements.** Results reflect your infrastructure and your network,
  not ours. A shared server would inject its own latency and noise.
- **Your provider spend stays yours.** Inference is billed to your account, and
  we never hold your API keys.
- **Privacy by construction.** Only metrics and summaries are uploaded. Prompts,
  responses, keys and private base URLs are stripped on the agent *and* again on
  the server, so a modified client cannot push them either.
- **Quota you cannot fake.** Plan limits are metered server-side, because the
  agent runs on hardware we do not control. Deleting local state does not grant
  extra runs.

```bash
infergauge login --server https://console.example.com   # once per machine
infergauge run infergauge.yaml --sync              # runs locally, records centrally
infergauge whoami                                       # tier, quota, account
infergauge logout
```

For CI, create an agent token in the console (Agents tab) and set
`INFERGAUGE_AGENT_TOKEN` in your pipeline instead of logging in interactively.

Deploying the console for a team? See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)
for TLS, email verification, systemd, backups and the security controls in place.

## Tests

```bash
python tests/regression.py        # 119 checks: config, metrics, quality, insights,
                                  # engine, providers (vs a mock endpoint), CLI,
                                  # server, reports, CI exports, legacy compatibility
npm install jsdom --no-save
node tests/dashboard_dom.js       # 20 checks: dashboard charts in a real DOM
python tests/test_console.py      # 66 checks: licensing, accounts, agent API, quota
node tests/console_ui.js          # 22 checks: console pages against a live server
                                  #   (start the console first: infergauge serve --port 8822)

pip install pymongo mongomock --break-system-packages
python tests/test_mongo_store.py  # 14 checks: MongoStore against mongomock, no Atlas
                                  #   account or network access needed - see
                                  #   docs/MONGODB_BACKEND.md
```

Both run automatically in every CI template.

## Architecture

```
                        InferGauge CLI
             init | run | dashboard | runs | validate
                             |
              +--------------+---------------+
              |                              |
         Test Engine                   Metrics Engine
   asyncio virtual users          1s window aggregates,
   load/stress/spike/endurance    exact percentiles, goodput,
              |                   cost, health score, insights
              |                              |
       AI Workload Providers                 |
   +---------+----------+----+               |
   |         |          |    |               |
 OpenAI   Anthropic   Azure  Local        FastAPI + SSE
 Gemini   (native)    OpenAI (Ollama,        |
 (compat)                    vLLM)           v
                                     InferGauge Dashboard
                              Performance | Tokens | Cost | SLA
                              (+ report.html / report.json / CI exit code)
```

Runs are persisted to `.infergauge/runs/` so `infergauge dashboard` and
`infergauge runs` work across sessions.

## Config reference

See `examples/` for complete files. All keys:

```yaml
name: My Test
application: My AI App
test_type: stress            # load | stress | spike | endurance
duration_s: 120
users: 1000
ramp_up_s: 30
think_time_s: 0.6
stress_step_users: 200       # stress staircase (optional)
stress_step_duration_s: 24
spike_baseline_users: 100    # spike shape (optional)
spike_at_s: 30
spike_duration_s: 20

provider:
  kind: simulator            # simulator | openai-compatible | anthropic
  base_url: https://api.openai.com/v1
  api_key_env: OPENAI_API_KEY
  model: gpt-4o-mini
  stream: true               # enables TTFT / inter-token measurement
  max_tokens: 200
  prompt: "..."
  system_prompt: ""
  timeout_s: 60
  sim_ttft_ms: 320           # simulator knobs
  sim_itl_ms: 16
  sim_output_tokens: 180
  sim_input_tokens: 950
  sim_saturation_users: 700
  sim_rate_limit_users: 880

sla:                         # omit any you don't need
  p95_latency_ms: 6000
  avg_latency_ms: null
  ttft_p95_ms: 900
  itl_p95_ms: 60
  error_rate_pct: 1.0
  min_throughput_rps: null
  max_cost_usd: 5.0
  min_goodput_pct: 90

pricing:                     # USD per 1M tokens
  input_per_1m: 2.0
  output_per_1m: 8.0

projection:                  # optional: realistic monthly cost estimate
  requests_per_day: 50000    # expected production volume (best option)
  # peak_hours_per_day: 8    # alternative: sustain test rate N hours/day
  days_per_month: 30.4
```

### How cost is calculated

```
total    = input_tokens/1M × pricing.input_per_1m
         + output_tokens/1M × pricing.output_per_1m
per_req  = total ÷ successful requests          ← a direct measurement, trust this
hourly   = total ÷ test_duration × 3600
```

Monthly cost is reported two ways, never conflated:

- **At expected volume** (when `projection.requests_per_day` is set) —
  `per_req × requests_per_day × days_per_month`. This is the number to budget with.
- **Peak ceiling** (the fallback) — `hourly × 730`, i.e. this test's spend rate
  sustained *every hour of the month*. Shown in amber and labelled `PEAK CEILING`
  because a stress test extrapolated 24/7 is a worst case, not a forecast.

Both figures state the **request volume they imply**, so a dollar number is always
sanity-checkable at a glance:

```
projected  $211,529.82/mo  PEAK CEILING - implies 63,597,600 requests/month
           set projection.requests_per_day for a realistic estimate
```

"Do we serve 64 million requests a month?" is a far easier question than staring
at a six-figure total.

Prices come from your config — nothing is looked up. Prompt-caching and batch
discounts are not modelled, so real bills are often lower. Failed requests are
counted as $0 (their tokens are unknown), so heavily-erroring runs may understate
slightly. A month is 365/12 = 30.4167 days = 730 hours (configurable via
`projection.days_per_month`), used by both projections.

**If the endpoint doesn't report usage**, InferGauge estimates tokens from text
length (~4 chars/token, ±20%), marks the cost `ESTIMATED`, and raises an insight —
rather than silently reporting $0 input cost, which is what a missing usage block
would otherwise produce.

Currency is rounded to 4 significant digits, not a fixed number of decimals, so
cheap-model costs survive: a $0.00012864 test reports `$0.00012864`, not `$0.0001`.
When cost per request is below a tenth of a cent, a per-1,000-requests figure is
shown alongside it. Displayed values stay internally consistent — cost/request ×
implied requests reproduces the monthly total.

## Roadmap

- Prompt-mix workloads (weighted pools, multi-turn conversations)
- Multi-provider comparison runs
- Distributed load generation
- Prometheus / OpenTelemetry export
- **Admin dashboard for the console**: today, discovering who signed up
  requesting a paid plan and minting/sending their license is an entirely
  manual, inbound process (see `docs/ADMIN_GUIDE.md`) — there is no built-in
  view listing accounts, requested plans, or license status across users.
  Worth prioritizing before volume makes the manual loop unmanageable.

## License

InferGauge is **source-available** under the [Business Source License 1.1](LICENSE),
not open source.

- **Allowed:** reading and auditing the source, internal and production use,
  CI/CD gating, testing your own or your employer's systems, and consulting
  work delivered to your clients.
- **Not allowed:** offering InferGauge to third parties as a hosted or managed
  service, embedding it in a product whose value comes mainly from InferGauge,
  or removing/bypassing its tier and quota enforcement.

Each released version converts to the **Apache License 2.0 on 2030-08-01** (or
four years after that version was published, whichever comes first).

See [COMMERCIAL.md](docs/business/COMMERCIAL.md) for the full picture and commercial licensing.
Bundled uPlot is MIT; runtime dependencies keep their own licenses.

**"InferGauge" is a trademark of InferGauge.** The license grants no trademark rights, and pre-release material shared under NDA may not be redistributed. See [NOTICE](NOTICE) for the full copyright, trademark, and confidentiality notice.

