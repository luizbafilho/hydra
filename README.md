Hydra Distributed HTTP Benchmark Tool
=====

Hydra is a Distributed HTTP Benchmark Tool capable of simulate thousands/ten of thousands users hitting your server as fast as it can.

It is the simplest distributed http benchmark tool you can find on the internet. No configuration need to run in multiples nodes.

## Installation
#### Erlang

Hydra requires Erlang 18. You can download it [here](https://www.erlang-solutions.com/downloads/download-erlang-otp)

#### Download
Download Hydra
```
$ wget https://github.com/luizbafilho/hydra/releases/download/v0.2/hydra
$ chmod +x hydra
```
## Usage

To use Hydra, it very simple.

```
$ ./hydra http://www.example.com
```

That will run with default options, `10` concurrent users for `10` seconds.

#### Options
```
Usage: hydra [options] url
  Options:
    -u, --users    Number of concurrent users. Default: 10 users
    -t, --time     Duration of benchmark in seconds. Default: 10 seconds
    -m, --method   Defines the HTTP Method used. Default: GET
    -p, --payload  Sets a payload
    -H, --header   Extra header to include in the request. It can be called more than once.
        --nodes    Defines the slaves nodes to run a distributed benchmark. You can specify
                   as much nodes you want. Ex. --nodes 172.20.21.2,172.20.21.3
        --slave    Starts Hydra in Slave Mode.
        --inet     Option required when running in Slave Mode. It defines the ip address
                   that is accessible to the master node.
    -h, --help     Displays this help message
```

## Distributed

First of all, make sure the `epmd` daemon is running. To do that run `epmd -daemon`. This daemon acts as a name server on all hosts involved in distributed Erlang computations.

To run a distributed benchmark, go to your slaves nodes and run Hydra in Slave Mode

```
$ hydra --slave --inet 172.20.1.1
```
The `--inet` options is required in order to enable the master node to reach the slave node.

Now, in the master node specify which slave node you want to join the benchmark.

```
$ hydra --nodes 172.20.1.1 http://www.example.com
```

That will spawn `10 users` on each node (master and slaves).

## Development

#### Elixir
Install Elixir in order to be able to build the project. [Elixir Installation](http://elixir-lang.org/install.html)

#### Building

1 - Download the project
```
$ git clone git@github.com:luizbafilho/hydra.git
```
2 - Get the dependencies
```
$ mix deps.get
```
3 - Build the project
```
$ mix escript.build
```
After the last step, the binary will be avaliable inside the projects's `bin` directory.
