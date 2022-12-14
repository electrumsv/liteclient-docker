# LiteClient Docker Compose

## Setup
```bash
git clone https://github.com/electrumsv/liteclient-docker.git
cd liteclient-docker
docker-compose up
```
Then start a new terminal on the container

```bash
docker exec -it electrumsv /bin/bash
```
Copy and paste the below command into that terminal in order to setup a new wallet within the container.

```bash
./electrum-sv create_jsonrpc_wallet -w demo
./electrum-sv daemon load_wallet -w demo
./electrum-sv daemon service_signup -w demo
```
When prompted, set a password. Repeat to create a wallet, then to load it, and finally to signup with listening service.  
  
---
  
## Usage  

Unlock the wallet for json-rpc use, note the password used here is "pass" - you should replace this with whatever your chosen password was from the setup stage.

```bash
curl --request POST \
  --url http://127.0.0.1:8332/ \
  --header 'Content-Type: text/plain' \
  --data '{"method": "walletpassphrase","params":["pass", 10000],"id": "unlock"}'
```

### Receiving
Get a new address to send some BSV to

```bash
curl --request POST \
  --url http://127.0.0.1:8332/ \
  --header 'Content-Type: text/plain' \
  --data '{"method": "getnewaddress","params":[""],"id": "receive"}'
```
Send a few sats to the response address using another wallet. [Handcash](https://handcash.io) for example.

You should see a txid appear in the logs as confirmation of receipt.

### Sending  
Send to address (the demo data will send 1000sats to deggen, please update to send elsewhere)

```bash
curl --request POST \
  --url http://127.0.0.1:8332/ \
  --header 'Content-Type: text/plain' \
  --data '{"method": "sendtoaddress","params":["1GKt5APkUWLsSp1r1gNGQue52jomPuDqGi", 0.00001000],"id": "send"}'
```

Your wallet data will be persisted in the directory `/electrumsv_data` at the root of the project.

For full details of the JSON-rpc api please [read the docs](https://electrumsv.readthedocs.io/en/develop/building-on-electrumsv/node-wallet-api.html).
