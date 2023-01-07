This app needs the following software installed:
```
sudo apt install jq
```

If you aren't able to set a static IP for the gateway,
you'll also need to:
```
sudo apt install arp-scan
```

The Tesla Gateway API is being reverse-engineered at:
```
https://github.com/vloschiavo/powerwall2
```

The format of the `creds.json` file for authenticating to the Tesla gateway is:

```
{"username":"customer","password":"my_password", "email":"my_email","force_sm_off":false}
```

Note that `"username"` above is literally `"customer"` (as opposed to `"installer"`)

