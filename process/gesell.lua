local ao = require('ao')
local json = require('json')
--[[
  This module implements the ao Standard Token Specification.

  Terms:
    Sender: the wallet or Process that sent the Message

  It will first initialize the internal state, and then attach handlers,
    according to the ao Standard Token Spec API:

    - Info(): return the token parameters, like Name, Ticker, Logo, and Denomination

    - Balance(Target?: string): return the token balance of the Target. If Target is not provided, the Sender
        is assumed to be the Target

    - Balances(): return the token balance of all participants

    - Transfer(Target: string, Quantity: number): if the Sender has a sufficient balance, send the specified Quantity
        to the Target. It will also issue a Credit-Notice to the Target and a Debit-Notice to the Sender

    - Mint(Quantity: number): if the Sender matches the Process Owner, then mint the desired Quantity of tokens, adding
        them the Processes' balance
]]
--

--[[
     Initialize State

     ao.id is equal to the Process.Id
   ]]
--
if not Balances then Balances = { } end

if Name ~= 'Gesells' then Name = 'Gesells' end

if Ticker ~= 'SELL' then Ticker = 'SELL' end

if Denomination ~= 3 then Denomination = 3 end -- same denomination as CRED

if not Logo then Logo = 'IBwlaHQy7m4nWnM_ZI2OF6BaflDrlsd9O8xJaZDSbbs' end

RATE = 0.0000002032 -- see calculation.md for why this is what it is
CRED = "Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc"

--[[
     Add handlers for each incoming Action defined by the ao Standard Token Specification
   ]]
--

--[[
     Info
   ]]
--
Handlers.add('info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(m)
  ao.send({
    Target = m.From,
    Name = Name,
    Ticker = Ticker,
    Logo = Logo,
    Denomination = tostring(Denomination)
  })
end)

-- Additional function to calculate effectBalance based on depreciation of SELL
-- We use the same compounding A = P(1 - r)^n formula described in Calculation.md

local function currentWorth(balance, mintBlock, currentBlock)
  local bal = tonumber(balance)
  local time = tonumber(mintBlock)
  local current = tonumber(currentBlock)
  local n = current - time

  local effectiveBalance = bal * (1 - RATE) ^ n

  return tostring(effectiveBalance)
end

--[[
     Balance
   ]]
--
Handlers.add('balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(m)
  local bal = '0'
  local mintBlock = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (m.Tags.Recipient and Balances[m.Tags.Recipient]) then
    bal = Balances[m.Tags.Recipient].value
    mintBlock = Balances[m.Tags.Recipient].mintBlock
  elseif Balances[m.From] then
    bal = Balances[m.From].value
    mintBlock = Balances[m.From].mintBlock
  end

  local effectiveBalance = currentWorth(bal, mintBlock, m['Block-Height'])

  ao.send({
    Target = m.From,
    effectiveBalance = effectiveBalance,
    Ticker = Ticker,
    Account = m.Tags.Recipient or m.From,
    Data = bal
  })
end)

--[[
     Balances. We will just return the whole Balances table in this case, rather than calculating effective balances
     for everyone, as that could get pretty expensive down the line.
   ]]
--
Handlers.add('balances', Handlers.utils.hasMatchingTag('Action', 'Balances'),
  function(m) ao.send({ Target = m.From, Data = json.encode(Balances) }) end)

--[[
     Transfer
   ]]
--
Handlers.add('transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(m)
  assert(type(m.Recipient) == 'string', 'Recipient is required')
  assert(type(m.Quantity) == 'string', 'Quantity is required')
  assert(tonumber(m.Quantity) > 0, 'Quantity must be greater than 0')

  if not Balances[m.From] then Balances[m.From].value = "0" end
  if not Balances[m.Recipient] then Balances[m.Recipient].value = "0" end

  local qty = tonumber(m.Quantity)
  local balance = Balances[m.From].value
  local mintBlock = Balances[m.From].mintBlock
  local effectiveBalance = tonumber(currentWorth(balance, mintBlock, m['Block-Height']))
  if effectiveBalance >= qty then
    -- we use the effectiveBalance here and change the mintBlock to now so that we only ever keep
    -- one object in the Balance table per process id.
    Balances[m.From].value = tostring(effectiveBalance - qty)
    Balances[m.From].mintBlock = tostring(m['Block-Height'])
    Balances[m.Recipient].value = tostring(tonumber(Balances[m.Recipient].value) + qty)
    Balances[m.Recipient].mintBlock = tostring(m['Block-Height'])

    --[[
         Only send the notifications to the Sender and Recipient
         if the Cast tag is not set on the Transfer message
       ]]
    --
    if not m.Cast then
      -- Send Debit-Notice to the Sender
      ao.send({
        Target = m.From,
        Action = 'Debit-Notice',
        Recipient = m.Recipient,
        Quantity = tostring(qty),
        Data = Colors.gray ..
            "You transferred " ..
            Colors.blue .. m.Quantity .. Colors.gray .. " to " .. Colors.green .. m.Recipient .. Colors.reset
      })
      -- Send Credit-Notice to the Recipient
      ao.send({
        Target = m.Recipient,
        Action = 'Credit-Notice',
        Sender = m.From,
        Quantity = tostring(qty),
        Data = Colors.gray ..
            "You received " ..
            Colors.blue .. m.Quantity .. Colors.gray .. " from " .. Colors.green .. m.Recipient .. Colors.reset
      })
    end
  else
    ao.send({
      Target = m.From,
      Action = 'Transfer-Error',
      ['Message-Id'] = m.Id,
      Error = 'Insufficient Balance!'
    })
  end
end)

--[[
    SELL is minted when CRED is sent to this process, on a 1:1 basis
   ]]
--
Handlers.add(
  "mint",
  function(m)
      return
          m.Tags.Action == "Credit-Notice" and
          m.From == CRED and
          m.Tags.Quantity >= "1000" and "continue" -- 1 CRED == 1000 CRED Units, must buy 1 or more SELL per tx
  end,
  function(m)
      if not Balances[m.Tags.Sender] then
        Balances[m.Tags.Sender] = {
          value = m.Tags.Quantity,
          mintBlock = m['Block-Height']
        }
      else
        local bal = Balances[m.Tags.Sender].value
        local mintBlock = Balances[m.Tags.Sender].mintBlock
        local effectiveBalance = currentWorth(bal, mintBlock, m['Block-Height'])
        Balances[m.Tags.Sender].value = tostring(tonumber(effectiveBalance) + tonumber(m.Tags.Quantity))
        Balances[m.Tags.Sender].mintBlock = m['Block-Height']
      end
  end
)

--[[
    SELL is burnt when other processes wish to redeem it for the underlying CRED, after depreciation is accounted for 
   ]]
--
Handlers.add(
  'burn',
  Handlers.utils.hasMatchingTag('Action', 'Burn'),
  function(m)
    assert(type(m.Quantity) == 'string', 'Quantity is required')
    assert(tonumber(m.Quantity) > 0, 'Quantity must be greater than 0')
    local qty = tonumber(m.Quantity)

    if not Balances[m.From] or Balances[m.From].value == 0 then
      ao.send({Target = m.From, Data="No SELL to burn"})
      return
    else
      local bal = Balances[m.From].value
      local mintBlock = Balances[m.From].mintBlock
      local effectiveBalance = tonumber(currentWorth(bal, mintBlock, m['Block-Height']))
      if effectiveBalance >= qty then
        Balances[m.From].value = tostring(effectiveBalance - qty)
        Balances[m.From].mintBlock = m['Block-Height']
        ao.send({Target = CRED, Action = "Transfer", Recipient = m.From, Quantity = m.Quantity})
      else
        ao.send({Target = m.From, Data = "Your SELL balance has depreciated. Try asking for less CRED."})
      end
    end
  end
)