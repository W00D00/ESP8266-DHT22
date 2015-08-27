
local GPIO0 = 3

local temperatureDHT22 = 0
local humidityDHT22 = 0

function ReadDHT22(pin)
	local dht22 = require("dht22")
	dht22.read(pin)
	local t = dht22.getTemperature()
	local h = dht22.getHumidity()
	temperatureDHT22 = (t / 10) .. "." .. (t % 10)
	humidityDHT22 = (h / 10)
	debugPrint("temperatureDHT22: " .. temperatureDHT22 .. " deg C")
	debugPrint("humidityDHT22:    " .. humidityDHT22 .. "%")
	dht22 = nil
	package.loaded["dht22"] = nil
end

local function sendDataToThingSpeak()
	debugPrint("send data to ThingSpeak...")
	conn = net.createConnection(net.TCP, 0)
	conn:on("receive", function(conn, payload) debugPrint(payload) end)
	conn:connect(80, '184.106.153.149')
	conn:send("GET /update?key=YOURTHINGSPEAKCHANNELAPIKEY&field1="  .. temperatureDHT22 .. "&field2=" .. humidityDHT22 .. " HTTP/1.1\r\n") 
	conn:send("Host: api.thingspeak.com\r\n") 
	conn:send("Accept: */*\r\n") 
	conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
	conn:send("\r\n")
	conn:on("sent", function(conn) debugPrint("Closing connection") conn:close() end)
	conn:on("disconnection", function(conn) debugPrint("Got disconnection...") end)
end

function main()
	ReadDHT22(GPIO0)
	sendDataToThingSpeak()
end

ReadDHT22(GPIO0)

tmr.alarm(1, 60000, 1, function() main() end)

srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
	conn:on("receive", function(conn, payload)
		debugPrint(payload)
		conn:send('HTTP/1.1 200 OK\r\nConnection: keep-alive\r\nCache-Control: private, no-store\r\n\r\n')
		conn:send('<!DOCTYPE HTML>')
		conn:send('<html lang="hu">')
		conn:send('<head>')
		conn:send('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">')
		conn:send('<meta http-equiv="refresh" content="60">')
		conn:send('<meta name="viewport" content="width=device-width, initial-scale=1">')
		conn:send('<title>Hőmérséklet (ESP8266 & DHT22)</title>')
		conn:send('</head>')
		conn:send('<body>')
		conn:send('<h1>Hőmérséklet (ESP8266 & DHT22)</h1>')
		conn:send('<h2>')
		conn:send('<input style="text-align: center" type="text" size=4 name="p" value="' .. temperatureDHT22 .. '"> C hőmérséklet<br><br>')
		conn:send('<input style="text-align: center" type="text" size=4 name="j" value="' .. humidityDHT22 .. '"> % páratartalom<br><br>')
		conn:send('</h2>')
		conn:send('</body></html>')		
		conn:on("sent", function(conn) conn:close() end)
	end)
end)
