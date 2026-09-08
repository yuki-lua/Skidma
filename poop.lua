repeat task.wait() until game:IsLoaded() task.wait(5)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync("Response cooldown is 3 seconds")

local API = "Bearer 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"
local Engine = "mistralai/mistral-7b-instruct"
local Cooldown = 3
local MaxLetter = 200
local Blacklisted = {"/", "#", "!"}

local LastQuestion = {}
local function IsValid(msg)
	if not msg or not msg.Text or not msg.TextSource then return false end
	if #msg.Text > MaxLetter then return false end
	for _, p in ipairs(Blacklisted) do
		if msg.Text:sub(1, #p) == p then return false end
	end
	return true
end

local function GetPlayerFromId(msg)
	local id = msg.TextSource and msg.TextSource.UserId
	return id and Players:GetPlayerByUserId(id) or nil
end

local function SendRequest(prompt)
	local response = http_request({
		Url = "https://openrouter.ai/api/v1/chat/completions",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = API,
			["HTTP-Referer"] = "https://www.roblox.com",
			["X-Title"] = "ChatBot"
		},
		Body = HttpService:JSONEncode({
			model = Engine,
			messages = {
				{ role = "system", content = "Answer with short and simple replies. Be friendly." },
				{ role = "user", content = prompt }
			}
		})
	})

	if not response or not response.Success then return end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
	return ok and data or nil
end

local function GetResponse(data)
	if not data or not data.choices or not data.choices[1] then return "I don't understand." end
	local msg = data.choices[1].message and data.choices[1].message.content
	return msg and msg:sub(1, MaxLetter):gsub("[<>]", "") or "Error."
end

TextChatService.MessageReceived:Connect(function(msg)
	if not IsValid(msg) then return end

	local player = GetPlayerFromId(msg)
	if not player then return end

	local now = os.time()
	if LastQuestion[player.UserId] and now - LastQuestion[player.UserId] < Cooldown then return end
	LastQuestion[player.UserId] = now

	local data = SendRequest(msg.Text)
	local reply = GetResponse(data)

	local channel = TextChatService.ChatInputBarConfiguration.TargetTextChannel
	if channel then
		channel:SendAsync(reply)
	end
end)
