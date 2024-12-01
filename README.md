# Monitor Node
Script to locally monitor Tendermint-based nodes.

This has been written by ZENODE and is licensed under the MIT-license (see [LICENSE](./LICENSE)).

## Requirements
- [jq](https://jqlang.github.io/jq/download)
- curl

## Features

- Will give an error message if the node is _unreachable_ (code 1).
- Will give an error message if the node is _catching up_ (code 2).
- Will give an error message if the node turned stale for _x_ amount of seconds (code 3).
- Can optionally ping and send logs to a monitor cronjob service as [healthchecks.io](https://healthchecks.io).
- _Not just limited to local_ nodes.
- Makes logs for historical data (a max of 1MB per log for one monitoring instance; this log gets archives as a .old-file, so it's actually 2MB of data you can have at max until you start to lose historical data).

## Quick-start

### 1. Cloning the repository

```
git clone https://github.com/zenodeapp/monitor-node.git
```

### 2.1 Run script (single time)
> [!WARNING]
> Make sure not to set the threshold too low; your local server's time might be inconsistent with the node.

```sh
bash monitor_node.sh [title] [rpc_url] [hc_id] [threshold_in_secs]
```

> _[title]_ works as an identifier for this monitoring instance (e.g. "gaia_node", "namada_node") [default: "node"].

> _[rpc_url]_ is the rpc endpoint for your node [default: "http://localhost:26657"].

> _[hc_id]_ is _optional_. Insert a healthchecks id here if you want to receive alerts.

> _[threshold_in_secs]_ is the stale block threshold. This tells after how many seconds the monitor has to conclude our node has halted [default: 300].

#### Example
```sh
bash monitor_node.sh "namada" "http://localhost:26657" "" 600
```
> This won't ping healthchecks and will decide a node halted if a block hasn't moved for 10 minutes.

### 2.2 Run script (as a cronjob)

Running the script as a cronjob is recommended. Use the command:

```
crontab -e
```

If this is your first time opening crontab, you may get asked to choose which editor you wish to use. Use whichever you're most comfortable with.

At the end of the file, add a line similar to the one below.

```sh
*/5 * * * * /bin/bash /full/path/to/monitor_node.sh [title] [rpc_url] [hc_id] [interval_in_secs]
```

> This will run the script every 5 minutes.

#### Example
```sh
*/10 * * * * /bin/bash /full/path/to/monitor_node.sh "gaia" "http://localhost:26657" "4ee83d8e-adad-4716-9b1b-7e1f759552f9"
```
> This will run the script every 10 minutes with the title "gaia", it will ping healthchecks at ID: "4ee83d8e-adad-4716-9b1b-7e1f759452f9" (dummy ID) and will default to a threshold of 300 (5 minutes).

</br>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
