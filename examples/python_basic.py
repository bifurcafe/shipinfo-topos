from shipinfo_sdk import ShipInfoClient

client = ShipInfoClient(base_url="http://127.0.0.1/topos/api")
print(client.capabilities().get("status"))
