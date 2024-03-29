echo "starting daemon..."
d="$(date +%s)"
mkdir "/root/.electrum-sv/$d"
./electrum-sv daemon -v=debug --enable-node-wallet-api -rpcuser="$RPC_USERNAME" -rpcpassword="$RPC_PASSWORD" --restapi-user="$REST_API_USERNAME" --restapi-password="$REST_API_PASSWORD" -walletnotify="python3 contrib/scripts/jsonrpc_wallet_event.py %s" > "/root/.electrum-sv/$d/daemon_log.txt" 2>&1 &
# We must wait until the daemon has had a chance to startup and write to the lockfile

status_code=404  # too early
status_code=$(
    curl -s -o /dev/null -w "%{http_code}" \
      --request POST --url "http://127.0.0.1:9999/v1/rpc/ping" \
      -u "$REST_API_USERNAME:$REST_API_PASSWORD" \
      --header 'Content-Type: text/plain'
)
until [ "$status_code" -eq "200" ];
do
  echo "$status_code - waiting for daemon to be ready.."
  sleep 2
  status_code=$(
    curl -s -o /dev/null -w "%{http_code}" \
      --request POST --url "http://127.0.0.1:9999/v1/rpc/ping" \
      -u "$REST_API_USERNAME:$REST_API_PASSWORD" \
      --header 'Content-Type: text/plain'
)
done

echo "checking if we need to create a new wallet..."
file="/root/.electrum-sv/wallets/$WALLET_NAME.sqlite"
new_wallet=false
if ! [ -e "$file" ]
then
  new_wallet=true
fi
echo $new_wallet

if [ "$new_wallet" = true ]
then
  echo "creating wallet..."
  ./electrum-sv -v=debug --no-password-check -wp="$WALLET_PASSWORD" create_jsonrpc_wallet -w "$WALLET_NAME" > "/root/.electrum-sv/$d/create_log.txt" 2>&1
fi
echo "loading wallet..."
./electrum-sv daemon -v=debug load_wallet -w "$WALLET_NAME" --walletpassword="$WALLET_PASSWORD" --restapi-user="$REST_API_USERNAME" --restapi-password="$REST_API_PASSWORD" > "/root/.electrum-sv/$d/load_log.txt" 2>&1
echo "syncing headers..."
# we must wait until electrumsv has synced headers before signing up to services
status_code="425" # assume too early
status_code=$(curl -s -o /dev/null -w "%{http_code}" --request POST --url http://127.0.0.1:8332/ --header 'Content-Type: text/plain' --data '{"method": "walletpassphrase","params":["pass", 10000],"id": "unlock"}')
until [ "$status_code" -ne "425" ];
do
  echo "$status_code - syncing headers, checking again in 10 seconds..."
  sleep 10
  status_code=$(curl -s -o /dev/null -w "%{http_code}" --request POST --url http://127.0.0.1:8332/ --header 'Content-Type: text/plain' --data '{"method": "walletpassphrase","params":["pass", 10000],"id": "unlock"}')
done
# now we may continue
if [ "$new_wallet" = true ]
then
  echo "service signup..."
  ./electrum-sv daemon -v=debug service_signup -w "$WALLET_NAME" --walletpassword="$WALLET_PASSWORD" --restapi-user="$REST_API_USERNAME" --restapi-password="$REST_API_PASSWORD" > "/root/.electrum-sv/$d/signup_log.txt" 2>&1
fi
printf "wallet is ready to use via json-rpc, link to documentation:
https://electrumsv.readthedocs.io/en/develop/building-on-electrumsv/node-wallet-api.html#api-usage
"

# Print logging output to console so the user doesn't have to go hunting for files
dir="/root/.electrum-sv/$d"
for filepath in "$dir"/*.txt; do
  filename=$(basename "$filepath")
  if [ -e "$filepath" ]; then
    if [ "$filename" = "daemon_log.txt" ]; then
      continue
    else
      echo
      echo "BASH SCRIPT LOGGING (see: $filepath):"
      cat "$filepath"
    fi
  fi
done

echo
echo "ELECTRUMSV DAEMON LOGGING:"
tail -f -n 10000 "$dir/daemon_log.txt"